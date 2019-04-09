mkdir -p /lustre/mmanders/gen_dynspec/int00473
cd /lustre/mmanders/gen_dynspec/int00473
cp -r /lustre/mmanders/bufferdata/sGRB/170112A/images/fullband_20170329/2016-12-12-00:32:18_0023802388807680.000000.ms /lustre/mmanders/gen_dynspec/int00473
echo vis="\"2016-12-12-00:32:18_0023802388807680.000000.ms"\" > ccal.py
echo cmplst="\"2016-12-12-00:32:18_0023802388807680.000000.cl"\" >> ccal.py
/home/mmanders/imaging_scripts/gen_dynspec_scripts/gen_model_ms_dynspec.py 2016-12-12-00:32:18_0023802388807680.000000.ms >> ccal.py
echo "ft(vis, complist=cmplst, usescratch=True)" >> ccal.py
echo "uvsub(vis)" >> ccal.py
casapy --nogui --nologger --log2term -c ccal.py
chgcentre 2016-12-12-00:32:18_0023802388807680.000000.ms 01:00:56.000 -17.11.24.00
echo vis="\"2016-12-12-00:32:18_0023802388807680.000000.ms"\" > split.py
echo outputvs="\"11-int00473.ms"\" >> split.py
echo spdub="\"11"\" >> split.py
echo "split(vis, outputvis=outputvs, spw=spdub)" >> split.py
casapy --nogui --nologger --log2term -c split.py
wsclean -tempdir /dev/shm/mmanders -size 512 512 -scale 0.03125 -weight briggs 0 -mgain 0.85 -gain 0.1 -channelsout 109 -joinchannels --name int00473-11 11-int00473.ms
mkdir -p /lustre/mmanders/bufferdata/sGRB/170112A/images/dynspec/int00473
cp -r *-image.fits /lustre/mmanders/bufferdata/sGRB/170112A/images/dynspec/int00473
rm -r /lustre/mmanders/gen_dynspec/int00473
