#!/bin/bash
# copied from /pipedata/workdir/sb/best_as_of_Nov19/tt_ppipe2.sh
# Updated by T.C. (May 2018)

# Set up environment
cfgfile=${1}
. $cfgfile
mkdir -p $tmpdir
mkdir -p $outdir
mkdir -p $scriptdir

commandFile=${scriptdir}/calibrationCommands.txt
if [ -f $commandFile ]; then rm $commandFile; fi
touch $commandFile

# Loop across subbands
for band in ${spws}; do

    i=1

    # Setup output filenames
    ti=`printf "T%cal" ${i}`            # T1cal
    basename=${band}-${ti}              # 00-T1cal
    work_subdir=${tmpdir}/${basename}   # /lustre/mmanders/gen_caltables/00-T1cal

    # Bandpass
    if $apply_bandpass; then
        bcalamps=${outdir}/bandpass/${basename}-spec.bcal
    fi

    calibCommand="/home/tcallister/Calibration/calibrate.sh
        --tmpdir $work_subdir
        --outdir $outdir
        --dadadir $dada_dir
        --band $band
        --dada $dada
        --basename $basename
        --flags $antflag_dir
        --exp_swap
        "

    if $stokes_cal; then calibCommand="${calibCommand} --stokes_cal"; fi

    echo ${calibCommand} >> $commandFile
	i=$(($i + 1))

done

# Run all jobs
#ipbs_taskfarm.py $commandFile
