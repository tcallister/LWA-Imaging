#!/bin/bash
# copied from /pipedata/workdir/sb/best_as_of_Nov19/tt_ppipe2.sh

# Parameter defaults
remove_rfi=false
do_pol_swap=false
exp_line_swap=false
aoflag=false
do_frq_offset=false
stokes_cal=false
flag_dir=''
bcalamps=''
apply_bandpass=false
bandpass=false
peel=false
zest=false
shave=false
prune=false
size=4096
scale=0.03125

TEMP=`getopt -o h --long tmpdir:,outdir:,dadadir:,band:,dada:,flags:,basename:,bcalamps:,remove_rfi,pol_swap,exp_swap,aoflag,freq_offset,stokes_cal,bandpass,peel,zest,shave,prune,size:,scale: -n 'calibrate.sh' -- "$@"`
eval set -- "$TEMP"
while true; do
    case "$1" in
        -h) echo -e $help_message ; shift ;;
        --tmpdir) echo -e "Working in directory:\t $2" ; tmpdir=$2 ; shift 2 ;;
        --outdir) echo -e "Saving output in directory:\t $2" ; outdir=$2 ; shift 2 ;;
        --dadadir) echo -e "Reading from directory:\t $2" ; dada_dir=$2 ; shift 2 ;;
        --band) echo -e "Subband:\t $2" ; band=$2 ; shift 2 ;;
        --dada) echo -e "Dada file:\t $2" ; dada=$2 ; shift 2 ;;
        --flags) echo -e "Using flags from:\t $2" ; flag_dir=$2 ; shift 2 ;;
        --basename) echo -e "Using calibration output basename:\t $2" ; basename=$2 ; shift 2 ;;
        --bcalamps) echo -e "Bcalamps (??):\t $2" ; bcalamps=$2; apply_bandpass=true; shift 2 ;;
        --remove_rfi) echo -e "Removing RFI: True" ; remove_rfi=true ; shift ;;
        --pol_swap) echo -e "Polarization swap: True" ; do_pol_swap=true ; shift ;;
        --exp_swap) echo -e "Expansion swap: True" ; exp_line_swap=true ; shift ;;
        --aoflag) echo -e "AOflagger: True" ; aoflag=true ; shift ;;
        --freq_offset) echo -e "Frequency offset: True" ; do_frq_offset=true ; shift ;;
        --stokes_cal) echo -e "Stokes calibration: True" ; stokes_cal=true ; shift ;;
        --bandpass) echo -e "Bandpass: True" ; bandpass=true ; shift ;;
        --peel) echo -e "Peel: True" ; peel=true ; shift ;;
        --zest) echo -e "Zest: True" ; zest=true ; shift ;;
        --shave) echo -e "Shave: True" ; shave=true ; shift ;;
        --prune) echo -e "Prune: True" ; prune=true ; shift ;;
        --size) echo -e "wsclean image size:\t $2" ; size=$2 ; shift ;;
        --scale) echo -e "wsclean pixel scale (degrees):\t $2" ; scale=$2 ; shift ;;
        --) shift ; break ;;
        *) echo "Error!" ; exit 1 ;;
    esac
done

# Create and move into working directory
mkdir -p $tmpdir
cd $tmpdir

# Copy across necessary files
ln -s /opt/astro/dada2ms/share/dada2ms/dada2ms.cfg.fiber dada2ms.cfg
ln -s /home/mmanders/sources_resolved.json sources.json     # sources_resolved doesn't account for source elevation
if [ -s $remove_rfi ]; then
    ln -s ${remove_rfi} sources_rfi.json
fi

# Define output filenames
ms=${basename}.ms
bcal=${basename}.bcal
Df0=${basename}.Df0     # phase calibration table for polarization calibration
cmplst=${basename}.cl
tt=${basename}.tt

# Convert dada to ms file
echo "COPYING"
echo ${dada_dir}/${band}/${dada}
dada2ms-tst3 ${dada_dir}/${band}/${dada} ${ms}

# Swap polarizations
if $do_pol_swap; then
    echo "POL SWAPPING!!!"
    swap_polarizations_from_delay_bug ${ms}
fi

# Swap lines
if $exp_line_swap; then
    echo "EXPANSION LINE SWAP!!!!"
    if [ ${dada:0:4} -ge 2018 ] && [ ${dada:5:2} -ge 3 ]; then
        /home/mmanders/scripts/swap_polarizations_expansion_201803/swap_polarizations_expansion ${ms}
    elif [ ${dada:0:4} -ge 2017 ] && [ ${dada:5:2} -ge 8 ] ; then
        /home/mmanders/scripts/swap_polarizations_expansion_201708/swap_polarizations_expansion ${ms}
    else
        /home/mmanders/scripts/swap_polarizations_expansion/swap_polarizations_expansion ${ms}
    fi
fi

# apply flags to MS
### Question: are all three of these the correct scripts to use?
if [ ! -z $flag_dir ]; then
    ms_flag_ants.sh ${ms} `cat ${flag_dir}/all.antflags`
    /home/sb/bin/flag_nov25.sh ${ms} < ${flag_dir}/all.blflags
    apply_sb_flags_single_band_ms2.py ${flag_dir}/all.chanflags ${ms} ${band}
fi

# flag with AOFlagger
if $aoflag; then
    echo "AOFLAGGING!!!!!"
    aoflagger ${ms}
fi

# Frequency shift
if $do_frq_offset; then
    echo "FREQ OFFSETTING"
    freq-offset_fix.py ${ms}
fi

###########################
# Build calibration script
###########################

echo "vis=\"${ms}\"" > ccal.py
echo "bcal=\"${bcal}\"" >> ccal.py
echo "bcalamps=\"${bcalamps}\"" >> ccal.py
echo "Df0=\"${Df0}\"" >> ccal.py
echo "cmplst=\"${cmplst}\"" >> ccal.py

if $stokes_cal; then
    gen_model_ms_stokes.py ${ms} >> ccal.py
else
    gen_model_ms.py ${ms} >> ccal.py
fi

### Question: Do we need to flag below some uv distance?
#echo \"flagdata(vis, uvrange='<300', flagbackup=False)\" >> ccal.py
echo "clearcal(vis, addmodel=True)" >> ccal.py
echo "ft(vis, complist=cmplst, usescratch=True)" >> ccal.py
echo "bandpass(vis, bcal, refant='34', uvrange='>15lambda', fillgaps=1)" >> ccal.py

if $stokes_cal; then
    if $apply_bandpass; then
        echo "polcal(vis, Df0, poltype='Dflls', gaintable=[bcal,bcalamps], refant='')" >> ccal.py
        echo "applycal(vis, gaintable=[bcal,bcalamps,Df0], calwt=[T,T,F], flagbackup=False)" >> ccal.py
    else
        echo "polcal(vis, Df0, poltype='Dflls', gaintable=[bcal], refant='')" >> ccal.py
        echo "applycal(vis, gaintable=[bcal,Df0], calwt=[T,F], flagbackup=False)" >> ccal.py
    fi
else
    if $apply_bandpass; then
        echo "applycal(vis, gaintable=[bcal,bcalamps], flagbackup=False)" >> ccal.py
    else
        echo "applycal(vis, gaintable=[bcal], flagbackup=False)" >> ccal.py
    fi
fi

####################
# Apply calibration
####################

casapy --nogui --nologger --log2term -c ccal.py

###########
# Not sure
###########

### Questions
# - bandpass vs. apply_bandpass ?
# - Do different ttcal versions need to be used for different options?
# - Different arguments to ttcal?

if $bandpass; then
    JULIA_PKGDIR=/opt/astro/mwe/ttcal-0.3.0/julia-packages/ julia-0.4.6 /home/mmanders/scripts/peel_restore.jl \"${ms}\"
elif $peel; then
    ttcal-0.2.0 peel --input ${ms} --sources sources.json --beam sine --minuvw 10 --maxiter 30 --tolerance 1e-4
elif $zest; then
    ~/scripts/gen_sourcesjson_resolved.py ${ms} >> sources_${band}.json
    cp sources_${band}.json ${outdir}
    JULIA_PKGDIR=/opt/astro/mwe/ttcal-0.3.0/julia-packages/ julia-0.4.6 /home/mmanders/scripts/zest_addtomodel.jl \"${ms}\" \"sources_${band}.json\"
elif $shave; then
    ttcal-0.2.0 shave --input ${ms} --sources sources_rfi.json --beam constant --minuvw 10 --maxiter 30 --tolerance 1e-4
elif $prune; then
    ttcal-0.3.0 prune ${ms} /lustre/mmanders/4dayrun/4hours/sources_rfi.json --beam constant --minuvw 2 --maxiter 30 --tolerance 1e-4
fi

if [ -s $remove_rfi ]; then
    ttcal-0.2.0 shave --input ${ms} --sources sources_rfi.json --beam constant --minuvw 10 --maxiter 30 --tolerance 1e-4
fi

/home/mmanders/imaging_scripts/flag_bad_chans.20180206.py ${ms} ${band}

if $bandpass; then
    wsclean -channelsout 109 -tempdir /dev/shm/mmanders -size $size $size -scale $scale -weight briggs 0 -name ${basename} ${ms}
elif $zest || $prune || $stokes_cal; then
    wsclean -tempdir /dev/shm/mmanders -pol I,V -size $size $size -scale $scale -weight briggs 0 -name ${basename} ${ms}
else
    echo "CLEANING!!"
    #wsclean -tempdir /dev/shm/mmanders -size $size $size -scale $scale -weight briggs 0 -name ${basename} ${ms}
    wsclean -tempdir ./ -size $size $size -scale $scale -weight briggs 0 -name ${basename} ${ms}
fi

##########
# Clean up
##########

# Clean output directory
if [ -d $outdir/$ms ]; then
    echo "Removing old output: $outdir/$ms"
    rm -r $outdir/$ms
fi
if [ -d $outdir/$bcal ]; then
    echo "Removing old output: $outdir/$bcal"
    rm -r $outdir/$bcal
fi
if [ -d $outdir/$Df0 ]; then
    echo "Removing old output: $outdir/$Df0"
    rm -r $outdir/$Df0
fi
if [ -d $outdir/$tt ]; then
    echo "Removing old output: $outdir/$tt"
    rm -r $outdir/$tt
fi

# Move results to output directory
mv $ms $outdir
if [ -d $bcal ]; then mv $bcal $outdir; fi
if [ -d $Df0 ]; then mv $Df0 $outdir; fi
if [ -d $tt ]; then mv $tt $outdir; fi
mv ${basename}-dirty.fits $outdir
mv ${basename}-image.fits $outdir
mv ${basename}.chans $outdir
mv ${basename}.png $outdir
if [ -f *.npz ]; then mv *.npz $outdir; fi

# Clean up
for file in $tmpdir/*.cl/*; do if [ -f $file ]; then rm $file; fi; done
rmdir *.cl
for file in $tmpdir/*.last; do if [ -f $file ]; then rm $file; fi; done
for file in $tmpdir/*.log; do if [ -f $file ]; then rm $file; fi; done
if [ -f $tmpdir/ccal.py ]; then rm $tmpdir/ccal.py; fi
if [ -f $tmpdir/dada2ms.cfg ]; then rm $tmpdir/dada2ms.cfg; fi
if [ -f $tmpdir/sources.json ]; then rm $tmpdir/sources.json; fi
rmdir $tmpdir



