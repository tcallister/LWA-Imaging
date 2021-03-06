#!/usr/bin/env python

import numpy as np
import pylab
import pyrap.tables as pt
import sys,os
from matplotlib.backends.backend_pdf import PdfPages
import pdb

# Check for input (ms file)
if len(sys.argv) != 3:
    print >> sys.stderr, 'Usage: %s <MS>' % sys.argv[0]
    sys.exit()

# open MS tables
t = pt.table(sys.argv[1])
tspw = pt.table(os.path.abspath(sys.argv[1])+'/SPECTRAL_WINDOW')

# initialize figure and pdf file
#pdf  = PdfPages(sys.argv[1][:-4]+'_autos.pdf')
pdf  = PdfPages(sys.argv[2]+'/autos.pdf')
pylab.figure(figsize=(15,10),edgecolor='Black')
pylab.clf()
ax1  = pylab.subplot(211)
ax2  = pylab.subplot(212)
#ax1.set_color_cycle(['blue','green','red','cyan','magenta','brown','black','orange'])
#ax2.set_color_cycle(['blue','green','red','cyan','magenta','brown','black','orange'])
ax1.set_color_cycle(['#a6cee3','#1f78b4','#b2df8a','#33a02c'])
ax2.set_color_cycle(['#a6cee3','#1f78b4','#b2df8a','#33a02c'])
legendstr = []

# select autos from MS table
tautos = t.query('ANTENNA1=ANTENNA2')

# iterate over antennas
for antind,tant in enumerate(tautos.iter("ANTENNA1")):

    print 'Plotting Ant %03d' % (antind)

    # Initialize arrays to hold amplitude spectra (22 subbands times 109 channels per subband)
    ampXallbands = np.zeros(22*109)
    ampYallbands = np.copy(ampXallbands)
    freqallbands = np.copy(ampXallbands)

    # iterate over subbands
    # (the tedious if statements are to correct for missing subbands in the ms file)
    tmpind = 0
    for ind,tband in enumerate(tant):

        # For all but the first band...
        if ind != 0:

            # If reference frequencies match, then proceed normally
            if tspw[ind]['REF_FREQUENCY'] == tspw[ind-1]['REF_FREQUENCY']:
                continue

            # If new reference frequency is not old ref frequency + bandwidth...
            elif tspw[ind]['REF_FREQUENCY'] != (tspw[ind-1]['REF_FREQUENCY'] + tspw[ind-1]['TOTAL_BANDWIDTH']):

                # Create placeholders for missing values
                numpad = (tspw[ind]['REF_FREQUENCY'] - tspw[ind-1]['REF_FREQUENCY'])/tspw[ind-1]['TOTAL_BANDWIDTH'] - 1
                amppad = np.zeros(109 * numpad) * np.nan
                frqpadstart = tspw[ind-1]['REF_FREQUENCY'] + tspw[ind-1]['TOTAL_BANDWIDTH'] + tspw[ind-1]['EFFECTIVE_BW'][0]/2.
                frqpadend   = frqpadstart + (tspw[ind-1]['TOTAL_BANDWIDTH'] * numpad)
                frqpad = np.linspace(frqpadstart, frqpadend + tspw[ind-1]['EFFECTIVE_BW'][0]/2., tspw[ind-1]['NUM_CHAN']*numpad)
                ampXallbands[tmpind*109:109*(tmpind+numpad)] = amppad
                ampYallbands[tmpind*109:109*(tmpind+numpad)] = amppad
                freqallbands[tmpind*109:109*(tmpind+numpad)] = frqpad
                tmpind += numpad

        # Save amplitudes 
        ampX = np.absolute(tband["DATA"][:,0])
        ampY = np.absolute(tband["DATA"][:,3])
        freq = tspw[ind]['CHAN_FREQ']
        ampXallbands[tmpind*109:109*(tmpind+1)] = ampX
        ampYallbands[tmpind*109:109*(tmpind+1)] = ampY
        freqallbands[tmpind*109:109*(tmpind+1)] = freq
        tmpind += 1

    legendstr.append('%03d' % (antind))
    ax1.plot(freqallbands/1.e6,10*np.log10(ampXallbands/1.e2))
    ax2.plot(freqallbands/1.e6,10*np.log10(ampYallbands/1.e2))

    # plot by ARX groupings
    if (np.mod(antind+1,4) == 0) and (antind != 0):

        pylab.xlabel('Frequency [MHz]')
        ax1.set_xticks(np.arange(0,100,2),minor=True)
        ax1.set_ylabel('Power [dB]')
        ax1.set_title('X',fontsize=18)
        ax1.set_ylim([40,100])
        ax2.set_xticks(np.arange(0,100,2),minor=True)
        pylab.ylabel('Power [dB]')
        ax2.set_title('Y',fontsize=18)
        ax2.set_ylim([40,100])
        ax1.legend(legendstr)
        ax2.legend(legendstr)

        if antind+1 in [64,128,192,248]:
            ax1.set_title('X -- fiber antennas',fontsize=18)
            ax2.set_title('Y -- fiber antennas',fontsize=18)
        elif antind+1 == 256:
            ax1.set_title('X -- leda antennas',fontsize=18)
            ax2.set_title('Y -- leda antennas',fontsize=18)
        elif antind+1 == 240:
            ax1.set_title('X -- fiber antennas 239,240',fontsize=18)
            ax2.set_title('Y -- fiber antennas 239,240',fontsize=18)

        pdf.savefig()
        # reiniatilize for new set of plots
        pylab.close()
        pylab.figure(figsize=(15,10),edgecolor='Black')
        ax1 = pylab.subplot(211)
        ax2 = pylab.subplot(212)
        ax1.set_color_cycle(['#a6cee3','#1f78b4','#b2df8a','#33a02c'])
        ax2.set_color_cycle(['#a6cee3','#1f78b4','#b2df8a','#33a02c'])
        legendstr = []

pdf.close()
