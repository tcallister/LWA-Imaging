#!/bin/bash

# Get command-line arguments
fitsname=${1}
size=${2}
scale=${3}
msfile=${@:4}

wsclean \
	-size $size $size \
	-scale $scale \
	-weighting-rank-filter 3 \
	-weighting-rank-filter-size 128 \
	-weight briggs 0 \
	-fitbeam \
    -niter 0 \
	-mgain 0.85 \
	-gain 0.1 \
	-multiscale \
	-multiscale-scale-bias 0.9 \
    -channelsout 109 \
	-joinchannels \
    -j 3 \
	-name $fitsname \
	$msfile
