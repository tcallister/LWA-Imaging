#!/bin/bash

# Filepaths and environment
cfgfile=${1}
. $cfgfile
flaggingCodeDir=$repo_dir/Flagging

# Make directories
mkdir -p $outdir/msfiles/
mkdir -p $antflag_dir

# Get name of ms file
msfile=${dada%.*}.ms

{
. $flaggingCodeDir/makeMSfiles.sh \
    --datadir $dada_dir \
    --dada $dada \
    --workingDir $outdir/msfiles/
}

# Flag bad autocorrelations
python $flaggingCodeDir/flag_bad_ants.py \
    -ms $outdir/msfiles/$msfile \
    -t $antflag_dir/bad_ants.ants

# Plot autocorrelations
python $flaggingCodeDir/plot_autos.py $outdir/msfiles/$msfile $outdir/flags/

# Copy existing baseline flags
cp $flaggingCodeDir/../flags/*bl $antflag_dir

python $flaggingCodeDir/flags_concatfiles.py \
    -s $antflag_dir

