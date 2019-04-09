#!/usr/bin/env python

from __future__ import division
import numpy as np
import pyrap.tables as pt
import os,argparse,sys
import numpy.ma as ma
from scipy.stats import skew
from scipy.ndimage import filters

def flag_bad_ants(msfile,target):

    """
    Input: msfile
    Returns list of antennas to be flagged based on autocorrelations.
    """

    # Read ms file, get all auto-powers (baselines with identical antennae)
    t       = pt.table(msfile, readonly=True)
    tautos  = t.query('ANTENNA1=ANTENNA2')

    # Initialize arrays to hold XX and YY data
    # 256 = number of antenna
    # 2398 = (22 subbands) x (109 channels per subband) = total number of frequency channels
    datacolxx = np.zeros((256,2398))
    datacolyy = np.copy(datacolxx)

    # Loop over antenna, 1-->256
    # Each tauto is a 22-element 
    for antind,tauto in enumerate(tautos.iter("ANTENNA1")):

        print(antind)

        # Loop across subbands and record autocorrelations
        for bandind,tband in enumerate(tauto):
            datacolxx[antind,bandind*109:(bandind+1)*109] = tband["DATA"][:,0]
            datacolyy[antind,bandind*109:(bandind+1)*109] = tband["DATA"][:,3]

    # Sum real and imaginary parts to get autocorrelation amplitudes
    datacolxxamp = np.sqrt( np.real(datacolxx)**2. + np.imag(datacolxx)**2. )
    datacolyyamp = np.sqrt( np.real(datacolyy)**2. + np.imag(datacolyy)**2. )

    # Convert to logarithmic (db) scale
    datacolxxampdb = 10*np.log10(datacolxxamp/1.e2)
    datacolyyampdb = 10*np.log10(datacolyyamp/1.e2)

    # median value for every antenna (taken along frequency axis)
    medamp_perantx = np.median(datacolxxampdb,axis=1)
    medamp_peranty = np.median(datacolyyampdb,axis=1)

    # Compute median of medians, and std of medians
    # Look for values that deviate significantly above/below median amplitude
    xthresh_pos = np.median(medamp_perantx) + np.std(medamp_perantx)
    xthresh_neg = np.median(medamp_perantx) - 2*np.std(medamp_perantx)
    ythresh_pos = np.median(medamp_peranty) + np.std(medamp_peranty)
    ythresh_neg = np.median(medamp_peranty) - 2*np.std(medamp_peranty)
    flags = np.where( (medamp_perantx > xthresh_pos) | (medamp_perantx < xthresh_neg) |\
              (medamp_peranty > ythresh_pos) | (medamp_peranty < ythresh_neg) )

    # Generate array to flag data from bad antennas, use to mask antennas
    flagmask = np.zeros((256,2398))
    flagmask[flags[0],:] = 1
    datacolxxampdb_mask = ma.masked_array(datacolxxampdb, mask=flagmask, fill_value=np.nan)
    datacolyyampdb_mask = ma.masked_array(datacolyyampdb, mask=flagmask, fill_value=np.nan)

    # Compute median spectra (taken over antennas)
    medamp_allantsx = np.median(datacolxxampdb_mask,axis=0)
    medamp_allantsy = np.median(datacolyyampdb_mask,axis=0)

    # Rescale each antenna by the median spectrum, and compute standard deviation of rescaled spectrum
    stdarrayx = np.array( [np.std(antarr/medamp_allantsx) for antarr in datacolxxampdb_mask] )
    stdarrayy = np.array( [np.std(antarr/medamp_allantsy) for antarr in datacolyyampdb_mask] )

    # this threshold was manually selected...should be changed to something better at some point
    flags2 = np.where( (stdarrayx > 0.02) | (stdarrayy > 0.02) )

    # Join flags
    flagsall = np.sort(np.append(flags,flags2))
    flagsallstr = [str(flag) for flag in flagsall]
    flagsallstr2 = ",".join(flagsallstr)

    with open(target,'w') as f:
        f.write(flagsallstr2)

    t.close()

def main():

    parser = argparse.ArgumentParser(description="Returns list of antennas to flag, based on power levels for \
                          autocorrelations in a single msfile. DOES NOT ACTUALLY FLAG \
                          THOSE ANTENNAS, JUST RETURNS A LIST TO BE FLAGGED.")
    parser.add_argument("-ms", help="Measurement set. Must be fullband measurement set, created with \
                    ~/imaging_scripts/gen_autos.py.")
    parser.add_argument("-t", help="Text file in which to save flagging list")
    args = parser.parse_args()
    flag_bad_ants(args.ms,args.t)

if __name__ == '__main__':
    main()
