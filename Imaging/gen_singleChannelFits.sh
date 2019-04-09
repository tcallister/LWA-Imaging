#!/bin/bash
# copied from /pipedata/workdir/sb/best_as_of_Nov19/tt_ppipe2.sh

# Environment
set -e
cfgfile=${1}
. $cfgfile

# Make directories
#workdir="/lustre/mmanders/gen_dynspec"
fitsdir=${outdir}/spectrogram_fits
#mkdir -p $workdir
mkdir -p $fitsdir

cleanCommands=${outdir}/do_channelCleanCommands.txt
touch $cleanCommands

# Copy across config file
cp $cfgfile $outdir

# Loop across directories containing each integration's msfiles
for integrationDir in $ms_dir/*/; do

    # Get integration number
    int=`basename $integrationDir`      # e.g. int00001

    # Make path to output directory
    fitsout=${fitsdir}/${int}
    mkdir -p $fitsout

    # Loop across individual msfiles
    for msfile in $integrationDir/*.ms/; do

        # Isolate ms filename, strip off spectral window and (suffixless) name
        msname=`basename $msfile`
        base=${msname%.*}
        spw=${base::2}
        #working_subdir=${workdir}/${int}/${base}/

        # Build cleaning command
        fitsprefix=${fitsout}/${int}-${spw}
        cleanCommand="/home/tcallister/Imaging/cleanChannels.sh $fitsprefix $fits_size $fits_scale $msfile"
        echo $cleanCommand >> $cleanCommands

    done

done


    ### if ${uvsubsrc}; add source to MODEL_DATA and uvsub it
#    if ${uvsubsrc}; then
#        echo -n "echo vis=\"\\\\\"${ms}\"\\\\\" > ccal.py;"
#        echo -n "echo cmplst=\"\\\\\"${base}.cl\"\\\\\" >> ccal.py;"
#        echo -n "/home/mmanders/imaging_scripts/gen_dynspec_scripts/gen_model_ms_dynspec.py ${ms} >> ccal.py;"
#        echo -n "echo \"ft(vis, complist=cmplst, usescratch=True)\" >> ccal.py;"
#        echo -n "echo \"uvsub(vis)\" >> ccal.py;"
#        echo -n "casapy --nogui --nologger --log2term -c ccal.py;"
#    fi

    ### Change phase center to location of source
#    echo -n "chgcentre ${ms} ${source_pos};"

        #echo -n "wsclean -tempdir /dev/shm/mmanders -size 512 512 -scale 0.03125 -weight briggs 0 -mgain 0.85 -gain 0.1 -channelsout 109 -joinchannels --name ${ti}-${band} ${band}-${ti}.ms;"
