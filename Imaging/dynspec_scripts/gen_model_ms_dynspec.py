#!/usr/bin/env python

from pyrap.measures import measures
from pyrap.tables import table
import math
import sys

ref_freq = 80.0
output_freq = 47.0

def flux80_47(flux_hi, sp):
	# given a flux at 80 MHz and a sp_index,
	# return the flux at 47 MHz.
	return flux_hi * 10 ** (sp * math.log(output_freq/ref_freq, 10))

srcs = [{'label': 'TauA', 'flux': '1770', 'alpha': -0.27,
	 'position': 'J2000 05h34m31.94s +22d00m52.2s'}]

if len(sys.argv) != 2:
	print >> sys.stderr, 'Usage: %s <MS>' % sys.argv[0]
	sys.exit()

t0 = table(sys.argv[1], ack=False).getcell('TIME', 0)
me = measures()
me.set_data_path('/opt/astro/casa-data')
ovro = me.observatory('OVRO_MMA')
time = me.epoch('UTC', '%fs' % t0)
me.do_frame(ovro)
me.do_frame(time)

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
	if elev < 0:
		del srcs[s]
	else:
		scale = math.sin(elev) ** 1.6
		srcs[s]['flux'] = str(flux80_47(float(srcs[s]['flux']), srcs[s]['alpha']) * scale)

print "cl.done()"
for s in srcs:
	print "cl.addcomponent(flux=%s, dir='%s', index=%s, spectrumtype='spectral index', freq='47MHz', label='%s')" % (s['flux'], s['position'], s['alpha'], s['label'])
print "cl.rename('%s.cl')" % sys.argv[1][:-3]
print "cl.done()"
