#!/bin/bash

# Get command-line arguments
fitsname=${1}
msfile=${@:2}

wsclean \
	-size 1024 1024 \
	-scale 0.125 \
	-weighting-rank-filter 3 \
	-weighting-rank-filter-size 128 \
	-weight briggs 0 \
	-fitbeam \
    -niter 0 \
	-mgain 0.85 \
	-gain 0.1 \
	-multiscale \
	-multiscale-scale-bias 0.9 \
	-joinchannels \
	-name $fitsname \
	$msfile

#	-size 1024 1024 \
#	-scale 0.125 \
    #-niter 50000 \
