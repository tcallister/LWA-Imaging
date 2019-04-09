import numpy as np
import sys
sys.path.append('/home/tcallister/modules/RadioFollowupTools/ImageFromFITS')
from gwMap import GWmap

limitData = np.load('upperLimits.npy')[()]
limits = np.array([])
ras = np.array([])
decs = np.array([])

for source in limitData:
    limits = np.append(limits,limitData[source]['q']['95'])
    ras = np.append(ras,limitData[source]['ra'])
    decs = np.append(decs,limitData[source]['dec'])

gwPath = '/home/tcallister/modules/RadioFollowupTools/ImageFromFITS/examples/LALInference_skymap.fits'
gw = GWmap(gwPath)

fig,ax = gw.plotMap()
fig.savefig('test.pdf')
