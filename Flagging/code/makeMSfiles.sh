#!/bin/bash

if [ $# -eq 0 ]; then
    echo -e $help_message
    exit
fi

TEMP=`getopt -o h --long datadir:,dada:,workingDir: -n 'gen_autos.sh' -- "$@"`
eval set -- "$TEMP"
while true; do
    case "$1" in
        -h) echo -e $help_message ; shift ;;
        --datadir) echo -e "Analyzing data from:\t $2" ; datadir=$2 ; shift 2 ;;
        --dada) echo -e "Loading dadafile:\t $2" ; dadafile=$2 ; shift 2 ;;
        --workingDir) echo -e "Working in directory:\t $2" ; workdir=$2 ; shift 2 ;;
        --) shift ; break ;;
        *) echo "Error!" ; exit 1 ;;
    esac
done

# Specify target msfile
ms=${dadafile%.*}.ms

# Create and cd into working directory
mkdir -p ${workdir}
cd $workdir

# Set up dada2ms config file
if [ ! -e $workdir/dada2ms.cfg ]; then ln -s /opt/astro/dada2ms/share/dada2ms/dada2ms.cfg.fiber $workdir/dada2ms.cfg; fi

# Convert first subband
#dada2ms-tst3 ${datadir}/00/${dadafile} $ms
dada2ms-tst3 ${datadir}/00/${dadafile} ${workdir}/00.ms
echo 00

# Convert and append remaining subbands
for band in {01..21}; do
    dada2ms-tst3 --append --addspw ${datadir}/${band}/${dadafile} $ms
    #dada2ms-tst3 ${datadir}/${band}/${dadafile} ${workdir}/${band}.ms
    echo ${band}
done

# Return to previous working directory
cd -
