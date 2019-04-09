import numpy as np
import glob
import h5py
import argparse
import sys
import re
sys.path.append("/home/tcallister/modules/RadioFollowupTools/ImageFromFITS/")

parser = argparse.ArgumentParser()
parser.add_argument('-spectrogramDir',help='Directory containing spectrogram h5 objects')
parser.add_argument('-outDir',help='Directory in which to store search results')
parser.add_argument('-dmMin',help='Minimum DM',type=float)
parser.add_argument('-dmMax',help='Maximum DM',type=float)
parser.add_argument('-thresh',help='Threshold sigma value',type=float)
parser.add_argument('-badInts',help='File containing bad integrations')
args = parser.parse_args()

# Open command file
cmdFile = "do_Dedispersion.txt"
commands = open(cmdFile,'w')

# Loop across spectrogram files
h5files = np.sort(glob.glob('{0}/*h5'.format(args.spectrogramDir)))
for h5file in h5files:
    
    command = "python2.7 /home/tcallister/Imaging/searchSpectrograms.py -h5 {0} -dmMin {1} -dmMax {2} -thresh {3} -outdir {4} -badInts {5}\n".\
            format(h5file,args.dmMin,args.dmMax,args.thresh,args.outDir,args.badInts)
    commands.write(command)


