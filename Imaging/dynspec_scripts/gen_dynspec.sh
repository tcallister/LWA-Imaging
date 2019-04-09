#!/bin/bash
# copied from /pipedata/workdir/sb/best_as_of_Nov19/tt_ppipe2.sh

set -e

. ./gen_dynspec.cfg

workdir="/lustre/mmanders/gen_dynspec"

mkdir -p $workdir
mkdir -p $outdir
cp gen_dynspec.cfg $outdir

i=1
for ms in `(cd ${ms_dir} && ls -1d *.ms)`; do
    basename=${ms%.*}
    ti=`printf "int%05d" ${i}`            # int00001
    work_subdir=${workdir}/${ti}          # /lustre/mmanders/gen_dynspec/int00001

    if [ -e ${outdir}/${ti} ] ; then
        i=$(($i + 1))
        continue
    fi

    echo -n "mkdir -p $work_subdir;"
    echo -n "cd $work_subdir;"

    # copy ${ms_dir}/${ms} to ${work_subdir}
    echo -n "cp -r ${ms_dir}/${ms} ${work_subdir};"

    # if ${uvsubsrc}; add source to MODEL_DATA and uvsub it
    if ${uvsubsrc}; then
        echo -n "echo vis=\"\\\\\"${ms}\"\\\\\" > ccal.py;"
        echo -n "echo cmplst=\"\\\\\"${basename}.cl\"\\\\\" >> ccal.py;"
        echo -n "/home/mmanders/imaging_scripts/gen_dynspec_scripts/gen_model_ms_dynspec.py ${ms} >> ccal.py;"
        echo -n "echo \"ft(vis, complist=cmplst, usescratch=True)\" >> ccal.py;"
        echo -n "echo \"uvsub(vis)\" >> ccal.py;"
        echo -n "casapy --nogui --nologger --log2term -c ccal.py;"
    fi

    # chgcentre to location of source
    echo -n "chgcentre ${ms} ${source_pos};"

    # split up into subbands
    echo -n "echo vis=\"\\\\\"${ms}\"\\\\\" > split.py;"
    for band in ${spws}; do
        echo -n "echo outputvs=\"\\\\\"${band}-${ti}.ms\"\\\\\" >> split.py;"
        echo -n "echo spdub=\"\\\\\"${band}\"\\\\\" >> split.py;"
        echo -n "echo \"split(vis, outputvis=outputvs, spw=spdub)\" >> split.py;"
    done
    echo -n "casapy --nogui --nologger --log2term -c split.py;"

    # image every channel
    for band in ${spws}; do
        echo -n "wsclean -tempdir /dev/shm/mmanders -size 512 512 -scale 0.03125 -weight briggs 0 -mgain 0.85 -gain 0.1 -channelsout 109 -joinchannels --name ${ti}-${band} ${band}-${ti}.ms;"
    done
    echo -n "mkdir -p ${outdir}/${ti};"
	echo -n "cp -r *-image.fits ${outdir}/${ti};"
	echo -n "rm -r $work_subdir;"
	echo
	i=$(($i + 1))
done
