#!/bin/bash

parentDir=$1
sourceList=$2
outputDir=$3
pathToCommandFile=$4

# Initialize command file
spectrumCommands=$pathToCommandFile/do_makeSpectra.txt
touch $spectrumCommands

# Loop across integrations
for intdir in $parentDir/int*/; do

    # Get integration name
    int=`basename $intdir`
    outputFile=${outputDir}/${int}.npy
    #outputFile=${outputDir}/${int}.h5

    # Write command
    spectrumCommand="/home/tcallister/Imaging/makeIntegrationSpectra.sh $sourceList $intdir $outputFile"
    echo $spectrumCommand >> $spectrumCommands

done
