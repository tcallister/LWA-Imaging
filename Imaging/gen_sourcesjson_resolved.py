#!/usr/bin/env python

from pyrap.measures import measures
from pyrap.tables import table
import math
import sys
from beam import beam
import numpy as np
import json
import pdb

if len(sys.argv) != 2:
    print >> sys.stderr, 'Usage: %s <MS>' % sys.argv[0]
    sys.exit()

srcs = [{'label': 'CasA', 'flux': '16530', 'alpha': -0.72, 'position': 'J2000 23h23m24s +58d48m54s'},
        {'label': 'CygA', 'flux': '16300', 'alpha': -0.58, 'position': 'J2000 19h59m28.35663s +40d44m02.0970s'}]
        #{'label': 'Sun',  'flux': '16000', 'alpha': 2.2  , 'position': 'SUN'},
        #{'label': 'TauA', 'flux': '1770' , 'alpha': -0.27, 'position': 'J2000 05h34m31.94s +22d00m52.2s'}]
        #{'label': 'TauA', 'flux': '1770' , 'alpha': -0.27, 'position': 'J2000 05h34m31.94s +22d00m52.2s'}]
        #{'label': 'VirA', 'flux': '2400' , 'alpha': -0.86, 'position': 'J2000 12h30m49.42338s +12d23m28.0439s'},

srcm = [
{
    "ref": "Michael (2016-07-30T10:52:45)",
    "name": "Cyg A",
    "components": [
        {
            "name": "1",
            "ra":"19h59m29.990s",
            "dec": "+40d43m57.53s",
            "I": 43170.55527073293,
            "Q": 0.0,
            "U": 0.0,
            "V": 0.0,
            "freq": 1.0e6,
            "index": [0.085, -0.178],
            "major-fwhm": 127.86780196141683,
            "minor-fwhm": 22.459884076169928,
            "position-angle": -74.50271323639498
        },
        {
            "name": "2",
            "ra":"19h59m24.316s",
            "dec": "+40d44m50.70s",
            "I": 6374.4647292670625,
            "Q": 0.0,
            "U": 0.0,
            "V": 0.0,
            "freq": 1.0e6,
            "index": [0.085, -0.178],
            "major-fwhm": 183.42701763410113,
            "minor-fwhm": 141.44188315233822,
            "position-angle": 43.449049376516
        }
    ]
},
{
    "name": "Cas A",
    "components": [
        {
            "Q": 0.0,
            "minor-fwhm": 84.1,
            "V": 0.0,
            "major-fwhm": 208.89999999999998,
            "name": "1",
            "ra": "23h23m12.780s",
            "freq": 1.0e6,
            "index": [-0.77],
            "I": 205291.01635813876,
            "dec": "+58d50m41.00s",
            "U": 0.0,
            "position-angle": 38.9
        },
        {
            "Q": 0.0,
            "minor-fwhm": 121.9,
            "V": 0.0,
            "major-fwhm": 230.89999999999998,
            "name": "2",
            "ra": "23h23m28.090s",
            "freq": 1.0e6,
            "index": [-0.77],
            "I": 191558.43164385832,
            "dec": "+58d49m18.10s",
            "U": 0.0,
            "position-angle": 43.8
        },
        {
            "Q": 0.0,
            "minor-fwhm": 63.4649,
            "V": 0.0,
            "major-fwhm": 173.26,
            "name": "3",
            "ra": "23h23m20.880s",
            "freq": 1.0e6,
            "index": [-0.77],
            "I": 159054.81199800296,
            "dec": "+58d50m49.92s",
            "U": 0.0,
            "position-angle": 121.902
        }
    ]
}
]


def flux80_47(flux_hi, sp, src_output_freq, src_ref_freq):
    # given a flux at reference frequency and a sp_index,
    # return the flux at MS center-frequency.
    if type(sp) is list:
        return flux_hi * 10 ** (sp[0] * math.log(src_output_freq/src_ref_freq, 10) + sp[1] * math.log(src_output_freq/src_ref_freq, 10)**2.)
    else:
        return flux_hi * 10 ** (sp * math.log(src_output_freq/src_ref_freq, 10))

def conv_deg(dec):
    if 's' in dec:
        dec = dec.split('s')[0]
    if 'm' in dec:
        dec, ss = dec.split('m')
        if ss == '':
            ss = '0'
    dd, mm = dec.split('d')
    if dd.startswith('-'):
        neg = True
    else:
        neg = False
    deg = float(dd) + float(mm)/60 + float(ss)/3600
    return '%fdeg' % deg

t0 = table(sys.argv[1],ack=False).getcell('TIME', 0)
me = measures()
me.set_data_path('/opt/casapy-42.0.28322-021-1-64b')
ovro = me.observatory('OVRO_MMA')
time = me.epoch('UTC', '%fs' % t0)
me.do_frame(ovro)
me.do_frame(time)

ref_freq = 80.0e6
output_freq = float(table(sys.argv[1]+'/SPECTRAL_WINDOW', ack=False).getcell('NAME', 0))
outbeam = beam(sys.argv[1])

# load in mountain azimuth elevations around OVRO
mountain_azel = np.load('/lustre/mmanders/LWA/modules/beam/mountain-azel.npz')
azarray = mountain_azel['azarray']
elarray = mountain_azel['elarray']

for s in range(len(srcs)-1,-1,-1):
    coord = srcs[s]['position'].split()
    d0 = None
    if len(coord) == 1:
        d0 = me.direction(coord[0])
        d0_j2000 = me.measure(d0, 'J2000')
        srcs[s]['position'] = 'J2000 %frad %frad' % (d0_j2000['m0']['value'], d0_j2000['m1']['value'])
    elif len(coord) == 3:
        coord[2] = conv_deg(coord[2])
        d0 = me.direction(coord[0], coord[1], coord[2])
    else:
        raise "Unknown direction"
    d = me.measure(d0, 'AZEL')
    elev = d['m1']['value']
    azim = d['m0']['value']

    if azim < 0:
        azdeg = 360 + azim*180./math.pi
    else:
        azdeg = azim*180./math.pi
    eldeg = elev*180./math.pi
    azmntind = np.where(np.min(np.abs(azdeg-azarray)) == np.abs(azdeg-azarray))
    elmnt = elarray[azmntind]

    if (elev < 0) | (eldeg < elmnt+0.5):
        del srcs[s]
    else:
        scale           = np.array(outbeam.srcIQUV(azim*180./math.pi, elev*180./math.pi))
        if np.isnan(scale[0]):
            del srcs[s]
            continue
        srcs[s]['flux'] = list(flux80_47(float(srcs[s]['flux']), srcs[s]['alpha'], output_freq, ref_freq) * scale)
        if srcs[s]['label'] == 'CygA':
            IQUVcomp1 = list(flux80_47(float(srcm[0]['components'][0]['I']), srcm[0]['components'][0]['index'], output_freq, 1.0e6) * scale)
            IQUVcomp2 = list(flux80_47(float(srcm[0]['components'][1]['I']), srcm[0]['components'][1]['index'], output_freq, 1.0e6) * scale)
            srcm[0]['components'][0]['I'] = IQUVcomp1[0]
            srcm[0]['components'][0]['Q'] = IQUVcomp1[1]
            srcm[0]['components'][0]['U'] = IQUVcomp1[2]
            srcm[0]['components'][0]['V'] = IQUVcomp1[3]
            srcm[0]['components'][0]['freq'] = output_freq
            srcm[0]['components'][1]['I'] = IQUVcomp2[0]
            srcm[0]['components'][1]['Q'] = IQUVcomp2[1]
            srcm[0]['components'][1]['U'] = IQUVcomp2[2]
            srcm[0]['components'][1]['V'] = IQUVcomp2[3]
            srcm[0]['components'][1]['freq'] = output_freq
        elif srcs[s]['label'] == 'CasA':
            IQUVcomp1 = list(flux80_47(float(srcm[1]['components'][0]['I']), srcs[s]['alpha'], output_freq, 1.0e6) * scale)
            IQUVcomp2 = list(flux80_47(float(srcm[1]['components'][1]['I']), srcs[s]['alpha'], output_freq, 1.0e6) * scale)
            IQUVcomp3 = list(flux80_47(float(srcm[1]['components'][2]['I']), srcs[s]['alpha'], output_freq, 1.0e6) * scale)
            srcm[1]['components'][0]['I'] = IQUVcomp1[0]
            srcm[1]['components'][0]['Q'] = IQUVcomp1[1]
            srcm[1]['components'][0]['U'] = IQUVcomp1[2]
            srcm[1]['components'][0]['V'] = IQUVcomp1[3]
            srcm[1]['components'][0]['freq'] = output_freq
            srcm[1]['components'][1]['I'] = IQUVcomp2[0]
            srcm[1]['components'][1]['Q'] = IQUVcomp2[1]
            srcm[1]['components'][1]['U'] = IQUVcomp2[2]
            srcm[1]['components'][1]['V'] = IQUVcomp2[3]
            srcm[1]['components'][1]['freq'] = output_freq
            srcm[1]['components'][2]['I'] = IQUVcomp3[0]
            srcm[1]['components'][2]['Q'] = IQUVcomp3[1]
            srcm[1]['components'][2]['U'] = IQUVcomp3[2]
            srcm[1]['components'][2]['V'] = IQUVcomp3[3]
            srcm[1]['components'][2]['freq'] = output_freq

with open('/home/mmanders/sources_rfiB.json') as jsonfile:
    rfiB = json.load(jsonfile)
fluxIvals  = [src['flux'][0] for src in srcs]
sortedinds = np.argsort(fluxIvals)[::-1]
jsondict = {"sources": []}
for ind in sortedinds:
    if srcs[ind]['label'] == 'Sun':
        jsondict["sources"].append({
            "ref": "gen_model_ms",
            "name": srcs[ind]['label'],
            "I": srcs[ind]['flux'][0],
            "Q": srcs[ind]['flux'][1],
            "U": srcs[ind]['flux'][2],
            "V": srcs[ind]['flux'][3],
            "freq": output_freq,
            "index": [srcs[ind]['alpha']]
        })
    elif srcs[ind]['label'] == 'CygA':
        jsondict["sources"].append(srcm[0])
    elif srcs[ind]['label'] == 'CasA':
        jsondict["sources"].append(srcm[1])
    else:
        #jsondict["sources"].append(rfiB[0])
        jsondict["sources"].append({
        "ref": "gen_model_ms",
        "name": srcs[ind]['label'],
        "ra": srcs[ind]['position'].split()[1],
        "dec": srcs[ind]['position'].split()[2],
        "I": srcs[ind]['flux'][0],
        "Q": srcs[ind]['flux'][1],
        "U": srcs[ind]['flux'][2],
        "V": srcs[ind]['flux'][3],
        "freq": output_freq,
        "index": [srcs[ind]['alpha']]
        })
jsondict["sources"].append(rfiB[0])

jstr = json.dumps(jsondict["sources"], sort_keys=True, indent=4)
print(jstr)
