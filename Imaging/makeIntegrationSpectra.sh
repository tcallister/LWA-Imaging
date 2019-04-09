#!/bin/bash

sourcelist=$1
integrationDir=$2
targetFile=$3

python2.7 /home/tcallister/modules/RadioFollowupTools/ImageFromFITS/spectrum.py \
    -src $sourcelist \
    -dir $integrationDir \
    -out $targetFile \
