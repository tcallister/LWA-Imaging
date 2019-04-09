import numpy as np
import argparse
import sys
import glob
sys.path.append('/home/tcallister/modules/RadioFollowupTools/ImageFromFITS/')

parser = argparse.ArgumentParser()
parser.add_argument('-srclist',help='Npy sourcelist file')
parser.add_argument('-spectra',help='Directory containing spectra files')
parser.add_argument('-h5size',help='Number of sources per h5 file',type=int)
parser.add_argument('-out',help='Output directory')
args = parser.parse_args()

# Get total number of sources
srclist = np.load(args.srclist)[()]
nSources = len(srclist['ra'])

# Get number of integrations
spectraFiles = np.sort(glob.glob("{0}/*npy".format(args.spectra)))
nIntegrations = len(spectraFiles)

# Generate indices with which to divide up source list
srcSlices = np.arange(0,int(np.ceil(float(nSources)/args.h5size))+1)*args.h5size

# Loop across slices, print commands to create h5 spectrogram file
commandFile = "do_makeSpectrograms.txt"
commands = open(commandFile,'w') 
for i in range(len(srcSlices[:-1])):

    command = "python2.7 /home/tcallister/modules/RadioFollowupTools/ImageFromFITS/createSpectrograms.py -srclist {0} -iStart {1} -iStop {2} -spectra {3} -out {4}/spectrograms_srcs{1}-{2}.h5 >> {4}/log_{1}-{2}.txt 2>&1".format(args.srclist,srcSlices[i],srcSlices[i+1],args.spectra,args.out)
    commands.write(command)
    commands.write("\n\n")

commands.close()

