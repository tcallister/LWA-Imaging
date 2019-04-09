#!/bin/bash
# copied from /pipedata/workdir/sb/best_as_of_Nov19/tt_ppipe2.sh

# Environment
integrationDir=${1}    # Top level directory holding all subband ms files for a given integration
ms=${2}                # Target ms filename

# Get array of subband ms files
#cd $integrationDir
ms_all=`ls -Qd ${integrationDir}/*.ms`
ms_arr=`echo ${ms_all} | tr ' ' ,`

# Write casapy commands
echo "concatvis=\"${ms}\"" > concat.py
echo "vis=[${ms_arr}]" >> concat.py
echo "concat(vis,concatvis=concatvis)" >> concat.py

# Run casa
casapy --nogui --nologger --log2term -c concat.py

# Clean up after Casa (casaviewer.wrapped-svr process still around)
for pid in `pgrep -P $$`; do
   kill -9 ${pid}
done

