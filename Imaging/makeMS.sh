#!/bin/bash
# copied from /pipedata/workdir/sb/best_as_of_Nov19/tt_ppipe2.sh

# Environment
PYTHONPATH=/opt/astro/pyrap-1.1.0/python:/lustre/mmanders/LWA/modules:$PYTHONPATH
PATH=/opt/astro/wsclean-1.11-gcc4.8.5_cxx11/bin:$PATH:/opt/astro/aoflagger-2.7.1-gcc4.8.5_cxx11/bin
. /opt/astro/env.sh

# Parameter defaults
remove_rfi=false
do_pol_swap=false
exp_line_swap=false
stokes_cal=false
applybandpasstable=false
aoflag=false
peel=false
shave=false
zest=false
prune=false
bcalamps=""
Df0=""

TEMP=`getopt -o h --long dadadir:,band:,dada:,ms:,workingdir:,outdir:,bcal:,antflag_dir:,bcalamps:,Df0:,remove_rfi,do_pol_swap,exp_line_swap,aoflag,peel,shave,zest,prune -n 'makeMS.sh' -- "$@"`
eval set -- "$TEMP"
while true; do
    case "$1" in
        -h) echo -e $help_message ; shift ;;
        --dadadir) echo -e "Reading from directory:\t $2" ; dadadir=$2 ; shift 2 ;;
        --band) echo -e "Band:\t $2" ; band=$2 ; shift 2 ;;
        --dada) echo -e "Converting dadafile:\t $2" ; dada=$2 ; shift 2 ;;
        --ms) echo -e "Converting to:\t $2" ; ms=$2 ; shift 2 ;;
        --workingdir) echo -e "Working in:\t $2" ; workingdir=$2 ; shift 2 ;;
        --bcal) echo -e "Using calibration table:\t $2" ; bcal=$2 ; shift 2 ;;
        --antflag_dir) echo -e "Using flags from:\t $2" ; antflag_dir=$2 ; shift 2 ;;
        --outdir) echo -e "Saving output to:\t $2" ; outdir=$2 ; shift 2 ;;
        --bcalamps) echo -e "Using bandpass table:\t $2" ; applybandpasstable=true; bcalamps=$2 ; shift 2 ;;
        --Df0) echo -e "Using Df0 table:\t $2" ; stokes_cal=true ; Df0=$2 ; shift 2 ;;
        --remove_rfi) echo -e "Removing RFI: True" ; remove_rfi=true ; shift ;;
        --do_pol_swap) echo -e "Polarization swap: True" ; do_pol_swap=true ; shift ;;
        --exp_line_swap) echo -e "Expansion line swap: True" ; exp_line_swap=true ; shift ;;
        --aoflag) echo -e "Aoflagging: True" ; aoflag=true ; shift ;;
        --peel) echo -e "Peel: True" ; peel=true ; shift ;;
        --zest) echo -e "Zest: True" ; zest=true ; shift ;;
        --shave) echo -e "Shave: True" ; shave=true ; shift ;;
        --prune) echo -e "Prune: True" ; prune=true ; shift ;;
        --) shift ; break ;;
        *) echo "Error!" ; exit 1 ;;
    esac
done

# Make directories and copy across needed files
mkdir -p $workingdir
mkdir -p $outdir
cd $workingdir
ln -s /opt/astro/dada2ms/share/dada2ms/dada2ms.cfg.fiber ${workingdir}/dada2ms.cfg
ln -s /home/mmanders/sources_resolved.json ${workingdir}/sources.json

if [ -s $remove_rfi ]; then
    echo "REMOVING RFI"
    ln -s ${remove_rfi} ${workingdir}/sources_rfi.json
fi

# If line swaps are needed...
if $do_pol_swap || $exp_line_swap; then

    dada2ms-tst3 ${dadadir}/${band}/${dada} ${outdir}/${ms}

    if $do_pol_swap; then
        echo "POL SWAP"
        swap_polarizations_from_delay_bug ${outdir}/${ms}

    elif $exp_line_swap; then
        echo "LINE SWAP"
        if [ ${dada:0:4} -ge 2017 ] && [ ${dada:5:2} -ge 8 ] ; then
            /home/mmanders/scripts/swap_polarizations_expansion_201708/swap_polarizations_expansion ${outdir}/${ms}
        else
            /home/mmanders/scripts/swap_polarizations_expansion/swap_polarizations_expansion ${outdir}/${ms}
        fi
    fi

    # Build python script with calibration commands
    echo "vis=\"${outdir}/${ms}\"" > ccal.py
    echo "bcal=\"${bcal}\"" >> ccal.py
    echo "bcalamps=\"${bcalamps}\"" >> ccal.py
    echo "Df0=\"${Df0}\"" >> ccal.py
    echo "clearcal(vis,addmodel=True)" >> ccal.py

    if $stokes_cal; then
        echo "STOKES CALIBRATION"
        echo "applycal(vis, gaintable=[bcal,Df0], calwt=[T,F], flagbackup=False)" >> ccal.py

    else 
        if $applybandpasstable; then
            echo "APPLYING BANDPASS"
            echo "applycal(vis, gaintable=[bcal,bcalamps], calwt=[T,F], flagbackup=False)" >> ccal.py
        else
            echo "applycal(vis, gaintable=[bcal], flagbackup=False)" >> ccal.py
        fi
    fi

    # Run CASA and clean up casaviewer.wrapped-svr process
    casapy --nogui --nologger --log2term -c ccal.py
    for pid in `pgrep -P $$`; do
        kill -9 ${pid}
    done

else
    dada2ms-tst3 --cal ${bcal} ${dada_dir}/${band}/${dada} ${outdir}/${ms}
fi

            
# apply flags to MS
if [ ! -z $antflag_dir ]; then
    echo "FLAGGING"
    ms_flag_ants.sh ${outdir}/${ms} `cat ${antflag_dir}/all.antflags`
    /home/sb/bin/flag_nov25.sh ${outdir}/${ms} < ${antflag_dir}/all.blflags
fi

# flag with AOFlagger
if $aoflag; then
    echo "AOFLAGGING"
    aoflagger ${outdir}/${ms}
fi

if $peel; then
    echo "PEELING"
    /home/tcallister/Imaging/gen_sourcesjson_resolved.py ${outdir}/${ms} >> sources_${band}.json
    cp sources_${band}.json ${outdir}/sources_`basename ${ms%.*}.json`
    JULIA_PKGDIR=/opt/astro/mwe/ttcal-0.3.0/julia-packages/ julia-0.4.6 /home/mmanders/scripts/peel_addtomodel.jl "${outdir}/${ms}" "sources_${band}.json"
elif $zest; then
    echo "ZESTING"
    /home/mmanders/scripts/gen_sourcesjson_resolved.py ${outdir}/${ms} >> sources_${band}.json
    cp sources_${band}.json ${outdir}/sources_`basename ${ms%.*}.json`
    JULIA_PKGDIR=/opt/astro/mwe/ttcal-0.3.0/julia-packages/ julia-0.4.6 /home/mmanders/scripts/peel_restore.tmp.jl "${outdir}/${ms}" "sources_${band}.json"
fi

if $shave; then
    echo "SHAVING"
    /home/mmanders/scripts/gen_sourcesjson.py ${outdir}/${ms} >> sources_${band}.json
    ttcal-0.2.0 shave --input ${outdir}/${ms} --sources ./sources_${band}.json --beam constant --minuvw 10 --maxiter 30 --tolerance 1e-4
elif $prune; then
    echo "PRUNING"
    ttcal-0.3.0 prune ${outdir}/${ms} /lustre/mmanders/4dayrun/4hours/sources_rfi.json --beam constant --minuvw 2 --maxiter 30 --tolerance 1e-4
fi

if [ -s $remove_rfi ]; then
   ttcal-0.2.0 shave --input ${outdir}/${ms} --sources sources_rfi.json --beam constant --minuvw 10 --maxiter 30 --tolerance 1e-4
fi

/home/mmanders/imaging_scripts/flag_bad_chans.20180206.py ${outdir}/${ms} ${band}

# Clean up
for file in $workingdir/*last; do if [ -f $file ]; then rm $file; fi; done
for file in $workingdir/*log; do if [ -f $file ]; then rm $file; fi; done
for file in $workingdir/*npz; do if [ -f $file ]; then rm $file; fi; done
for file in $workingdir/*json; do if [ -f $file ]; then rm $file; fi; done
if [ -f $workingdir/ccal.py ]; then rm $workingdir/ccal.py; fi
if [ -f $workingdir/dada2ms.cfg ]; then rm $workingdir/dada2ms.cfg; fi
rmdir $workingdir

# Clean up after Casa (casaviewer.wrapped-svr process still around)
for pid in `pgrep -P $$`; do
    kill -9 ${pid}
done

