#!/usr/bin/env python

from __future__ import division
import numpy as np
import pyrap.tables as pt
import os,argparse,sys
import numpy.ma as ma
from scipy.stats import skew
from scipy.ndimage import filters

def flag_bad_chans(msfile, band):

    """
    Input: msfile
    Finds remaining bad channels and flags those in the measurement set. Also writes out text file that lists
    flags that were applied.
    """

    # Read msfile, get all cross-correlations
    t       = pt.table(msfile, readonly=False)
    tcross  = t.query('ANTENNA1!=ANTENNA2')
    datacol = tcross.getcol('CORRECTED_DATA')
    flagcol = tcross.getcol('FLAG')

    print(np.shape(datacol))
    print(np.shape(flagcol))
    sys.exit()
    
    datacolxx = datacol[:,:,0]
    datacolyy = datacol[:,:,3]

    datacolxxamp = np.sqrt( np.real(datacolxx)**2. + np.imag(datacolxx)**2. )
    datacolyyamp = np.sqrt( np.real(datacolyy)**2. + np.imag(datacolyy)**2. )

    flagarr = flagcol[:,:,0] | flagcol[:,:,3]   # probably unnecessary since flags are never pol-specific,
                                                # but doing this just in cases

    datacolxxamp_mask = ma.masked_array(datacolxxamp, mask=flagarr, fill_value=np.nan)
    datacolyyamp_mask = ma.masked_array(datacolyyamp, mask=flagarr, fill_value=np.nan)

    skewxx = np.max(datacolxxamp_mask,axis=0)
    skewyy = np.max(datacolyyamp_mask,axis=0)
    meanxx = np.mean(datacolxxamp_mask,axis=0)
    meanyy = np.mean(datacolyyamp_mask,axis=0)

    skewxx_medfilt = filters.median_filter(skewxx,size=10)
    skewyy_medfilt = filters.median_filter(skewyy,size=10)

    skewxx_norm = skewxx/skewxx_medfilt
    skewyy_norm = skewyy/skewyy_medfilt
    
    skewxx_norm_stdfilt = filters.generic_filter(skewxx_norm, np.std, size=25)
    skewyy_norm_stdfilt = filters.generic_filter(skewyy_norm, np.std, size=25)
    skewvalxx = 1 - 10*np.min(skewxx_norm_stdfilt)
    skewval2xx = 1 + 10*np.min(skewxx_norm_stdfilt)
    skewvalyy = 1 - 10*np.min(skewyy_norm_stdfilt)
    skewval2yy = 1 + 10*np.min(skewyy_norm_stdfilt)
    meanxx_stdfilt = filters.generic_filter(meanxx, np.std, size=25)
    meanyy_stdfilt = filters.generic_filter(meanyy, np.std, size=25)

    # bad channels tend to have skewness values close to zero or slightly negative, compared to
    # good channels, which have significantly positive skews, or right-skewed distributions.
    #flaglist = np.where( (skewxx < 1) | (skewyy < 1)  )
    flaglist = np.where( (skewxx_norm < skewvalxx) | (skewyy_norm < skewvalyy) |   \
                         (skewxx_norm > skewval2xx) | (skewyy_norm > skewval2yy) | \
                         (meanxx > np.median(meanxx)+100*np.min(meanxx_stdfilt))  | \
                         (meanyy > np.median(meanyy)+100*np.min(meanyy_stdfilt)) ) 
    #import pylab
    #pylab.ion()
    #pylab.plot(skewxx_norm, '.', color='Blue')
    #pylab.plot(skewyy_norm, '.', color='Green')
    #pylab.hlines(skewvalxx, 0, 108, color='blue')
    #pylab.hlines(skewval2xx, 0, 108, color='blue')
    #pylab.hlines(skewvalyy, 0, 108, color='green')
    #pylab.hlines(skewval2yy, 0, 108, color='green')
    #pylab.plot(flaglist[0],skewxx_norm[flaglist], '.', color='Red')
    #pylab.plot(flaglist[0], skewyy_norm[flaglist], '.', color='Red')
    #pylab.grid('on')
    #pylab.figure()
    #pylab.plot(meanxx, '.', color='Blue')
    #pylab.plot(meanyy, '.', color='Green')
    #pylab.hlines(np.median(meanxx)+100*np.min(meanxx_stdfilt), 0, 108, color='Blue')
    #pylab.hlines(np.median(meanyy)+100*np.min(meanyy_stdfilt), 0, 108, color='Green')
    #pylab.grid('on')
    #import pdb
    #pdb.set_trace()

    #################################################
    #this is for testing purposes only
    #generate plot of visibilities for quick check of how well flagging performed
    import matplotlib as mpl
    mpl.use('Agg')
    import matplotlib.pyplot as plt
    plt.figure(figsize=(5,10))
    chans = np.arange(0,109)
    for chan in chans:
        if chan not in flaglist[0]:
            chanpts = np.zeros(len(datacolxxamp_mask[:,chan]))+chan
            plt.plot(datacolxxamp_mask[:,chan],chanpts, '.', color='Blue', markersize=0.5)
            plt.plot(datacolyyamp_mask[:,chan],chanpts, '.', color='Green', markersize=0.5)
    plt.ylim([0,108])
    plt.ylabel('channel')
    plt.xlabel('Amp')
    plt.gca().invert_yaxis()
    plotfile = os.path.splitext(os.path.abspath(msfile))[0]+'.png'
    plt.savefig(plotfile)

    ################################################

    if flaglist[0].size > 0:
        # turn flaglist into text file of channel flags
        textfile = os.path.splitext(os.path.abspath(msfile))[0]+'.chans'
        chans    = np.arange(0,109)
        chanlist = chans[flaglist]
        with open(textfile, 'w') as f:
            for chan in chanlist:
                f.write('%02d:%03d\n' % (np.int(band),chan))

        # write flags into FLAG column
        flagcol_altered = t.getcol('FLAG')
        flagcol_altered[:,flaglist,:] = 1
        t.putcol('FLAG', flagcol_altered)

    t.close()

def main():
    parser = argparse.ArgumentParser(description="Flag bad channels and write out list of channels that were \
                                                  flagged into text file of same name as ms. MUST BE RUN ON \
                                                  SINGLE SUBBAND MS.")
    parser.add_argument("msfile", help="Measurement set.")
    parser.add_argument("band", help="Subband number.")
    args = parser.parse_args()
    flag_bad_chans(args.msfile,args.band)

if __name__ == '__main__':
    main()
