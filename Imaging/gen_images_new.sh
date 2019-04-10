#!/bin/bash
# copied from /pipedata/workdir/sb/best_as_of_Nov19/tt_ppipe2.sh

# Environment
cfgfile=${1}
. $cfgfile

# Make directories
mkdir -p $tmpdir
mkdir -p $outdir
mkdir -p $scriptdir
msdir=$outdir/msfiles
fitsdir=$outdir/fits
mkdir -p $msdir
mkdir -p $fitsdir

# Copy across dadalist and configuration files
cp $cfgfile $outdir
cp $dadalist $outdir

msCommands=$scriptdir/do_makeMS.txt
if [ -f $msCommands ]; then rm $msCommands; fi
touch $msCommands

cleanCommands=$scriptdir/do_cleanCommands.txt
if [ -f $cleanCommands ]; then rm $cleanCommands; fi
touch $cleanCommands

if $imageallsubbands; then
    concatCommands=$outdir/do_concatCommands.txt
    if [ -f $concatCommands ]; then rm $concatCommands; fi
    touch $concatCommands
fi

# Loop across files in dadalist
i=$numberstart
for dada in `cat $dadalist`; do

    # Format integration label
    ti=`printf "int%05d" ${i}`           # int00001

    # Loop across subbands
    for band in ${spws}; do

        # Format output ms name
        basename=${ti}-${band}		         # e.g. int00001-04
        ms=${band}-${dada%.*}.ms	 # e.g. 04-2015-09-20-13:33:54-xxxxxxxxxxxxxxxx.00000.ms

        # Calibration tables
        bcal=${caldir}/${band}-T1al.bcal
        tmp_subdir=${tmpdir}/${ti}/${band} # /lustre/mmanders/gen_movie/int00001/04

        msCommand="$repo_dir/Imaging/makeMS.sh
            --dadadir $dada_dir
            --band $band
            --dada $dada
            --ms $ms
            --workingdir $tmp_subdir
            --bcal $bcal
            --antflag_dir $antflag_dir
            --outdir $msdir/$ti
            "

        if $exp_line_swap; then msCommand="${msCommand} --exp_line_swap"; fi
        if $peel; then msCommand="${msCommand} --peel"; fi

        echo $msCommand >> $msCommands

        #if ! $imageallsubbands; then
        #    echo -n "wsclean -tempdir /dev/shm/tcallister -size 4096 4096 -scale 0.03125 -weighting-rank-filter 3 -weighting-rank-filter-size 128 -weight briggs 0 -fitbeam -mgain 0.85 -gain 0.1 -niter 0 -multiscale -multiscale-threshold-bias 0.9 -casamask /lustre/mmanders/bufferdata/sGRB/170112A/images/cleanmask.mask -name ${work_subdir}/${basename} $ms;"
            #echo -n "cp -r ${work_subdir}/*${ti}*-image.fits ${outdir};"
        #    echo -n "cp -r ${work_subdir}/*${ti}*-image.fits ${outdir};"
        #    echo -n "cp -r ${work_subdir}/${ms} ${outdir};"
        #    echo -n "rm -r $work_subdir;"
        #fi

    done

    #if $imageallsubbands; then
    if $concat; then

        concatCommand="$repo_dir/Imaging/concat.sh ${msdir}/${ti}/ ${msdir}/${dada%.*}.ms"
        echo $concatCommand >> $concatCommands

        cleanCommand="$repo_dir/Imaging/clean.sh ${fitsdir}/${dada%.*} ${msdir}/${dada%.*}.ms"
        echo $cleanCommand >> $cleanCommands

    else

        cleanCommand="$repo_dir/Imaging/clean.sh ${fitsdir}/${dada%.*} ${msdir}/${ti}/*.ms"
        echo "$cleanCommand" >> $cleanCommands

    fi

	i=$(($i + 1))

done
