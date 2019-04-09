import numpy as np
import argparse
import h5py
import sys
sys.path.append('/home/tcallister/modules/RadioFollowupTools/ImageFromFITS')
from spectrogram import Spectrogram
from runDedispersion import *

def searchSpectrogramH5(h5file,DMmin,DMmax,thresh,plotDir,badIntegrations=None):

    # Instantiate dictionary to hold directional upper limits
    #upperLimitDict={}
    cdfDict={}

    # Get h5 suffix
    suffix = h5file.split('.')[-2].split('_')[-1]

    # Read h5 data, loop across sources
    f = h5py.File(h5file,'r')
    for i,srcNumber in enumerate(f):

        print(srcNumber)

        # Load spectrogram
        s = Spectrogram.fromH5(h5file,srcNumber,flagIntegrations=badIntegrations)

        # Dedisperse and save quantiles
        fluxes,cdfs = dedispersionSearch(s,DMmin,DMmax,thresh,plotDir)
        #upperLimitDict[int(srcNumber)] = {'q':quantiles,'ra':s.ra,'dec':s.dec}
        cdfDict[int(srcNumber)] = {'flux':fluxes,'cdf':cdfs}

    #np.save('{0}/upperLimits_{1}.npy'.format(plotDir,suffix),upperLimitDict)
    np.save('{0}/cdfs_{1}.npy'.format(plotDir,suffix),cdfDict)

if __name__=="__main__":

    parser = argparse.ArgumentParser()
    parser.add_argument('-h5',help='H5 spectrogram file to search')
    parser.add_argument('-dmMin',help='Minimum DM',type=float)
    parser.add_argument('-dmMax',help='Maximum DM',type=float)
    parser.add_argument('-thresh',help='Threshold sigma value',type=float)
    parser.add_argument('-outdir',help='Directory in which to save output')
    parser.add_argument('-badInts',help='File containing bad integrations')
    args = parser.parse_args()

    badIntegrations = np.loadtxt(args.badInts,delimiter=',',dtype=int).tolist()
    searchSpectrogramH5(args.h5,args.dmMin,args.dmMax,args.thresh,args.outdir,badIntegrations=badIntegrations)

    """
    badIntegrations = [100,101,102,337,339,340,341,342,343,344,357,388,419,511,512]
    searchSpectrogramH5('/lustre/tcallister/GW170104_recalibration/imaging/spectrograms/spectrogram_h5/spectrograms_srcs33000-34000.h5',\
            113.,630.,7.9,\
            'testdir',badIntegrations=badIntegrations)
    """
