#!/usr/bin/env python

import numpy as np
from glob import glob
import sys, os, argparse

parser = argparse.ArgumentParser()
parser.add_argument('-s',help="Directory from which to read flags",type=str)
args = parser.parse_args()
flagpath = os.path.abspath(args.s)

# ANTENNA FLAGS #
# read in all *.ants antenna files
antlist = np.array([])
antennafiles = np.sort(glob(flagpath+'/*.ants'))
for antfile in antennafiles:
    output = np.genfromtxt(antfile,delimiter=',',dtype=int)
    antlist = np.append(antlist,output)

# Sort and remove duplicates, and write out final antenna flag list
finalantlist = np.unique(np.sort(antlist))
f = open(flagpath+'/all.antflags', 'w')
f.write(','.join([str(int(i)) for i in finalantlist]))
f.close()

# BASELINE FLAGS #
# read in all *.bl baseline files
bllist = np.array([])
baselinefiles = np.sort(glob(flagpath+'/*.bl'))
for blfile in baselinefiles:
    output = np.genfromtxt(blfile,delimiter='\n',dtype=str)
    bllist = np.append(bllist,output)

# remove baselines that have already been flagged by antenna
bl_by_ant = []
for bl in bllist:
    ant1 = int(bl.split('&')[0])
    ant2 = int(bl.split('&')[1])
    if (ant1 not in finalantlist) and (ant2 not in finalantlist):
        if ant1 < ant2:
            bl_by_ant.append((ant1,ant2))
        else:
            bl_by_ant.append((ant2,ant1))

# sort and remove duplicates
dtype = [('ANT1', int), ('ANT2', int)]
bl_by_ant = np.array(bl_by_ant,dtype=dtype)
finalbllist = np.unique(np.sort(bl_by_ant, order=['ANT1','ANT2']))

# write out final baseline flag list
fbl = open(flagpath+'/all.blflags', 'w')
for bl in finalbllist:
    fbl.write('%d&%d\n' % (bl[0],bl[1]))
fbl.close()

# CHANNEL FLAGS #
# read in all *.chans channel files
chanslist = np.array([])
channelfiles = np.sort(glob(flagpath+'/*.chans'))
for chansfile in channelfiles:
    output = np.genfromtxt(chansfile,delimiter='\n',dtype=str)
    chanslist = np.append(chanslist,output)

# Separate subband and channel numbers
chanslistbysubb = []
for chan in chanslist:
    subband = int(chan.split(':')[0])
    channel = int(chan.split(':')[1])
    chanslistbysubb.append((subband,channel))

# Sort and remove any duplicates
dtype = [('subband', int), ('channel', int)]
chanslistbysubb = np.array(chanslistbysubb,dtype=dtype)
finalchanslist = np.unique(np.sort(chanslistbysubb, order=['subband','channel']))

# write out final channel flag list
fchans = open(flagpath+'/all.chanflags', 'w')
for chan in finalchanslist:
    fchans.write('%02d:%03d' % (chan[0],chan[1]))
    if chan != finalchanslist[-1]:
        fchans.write('\n')
fchans.close()
