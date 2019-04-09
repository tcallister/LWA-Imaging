#!/bin/bash

if [ -e ./gen_dynspec_exec.txt ]; then rm ./gen_dynspec_exec.txt; fi
if ls /home/mmanders/job_staging/gen_dynspec.*.sh 1> /dev/null 2>&1; then rm /home/mmanders/job_staging/gen_dynspec.*.sh; fi
FILE=gen_dynspec.txt
j=0
while read line; do
    num=`printf "%02d" $j`
    cmds=$(IFS=\;; set -- $line; printf "%s\n" "$@")
    echo "$cmds" > /home/mmanders/job_staging/gen_dynspec.${num}.sh
    echo "PYTHONPATH=/opt/astro/pyrap-1.1.0/python:/lustre/mmanders/LWA/modules:\$PYTHONPATH; PATH=/opt/astro/wsclean-1.11-gcc4.8.5_cxx11/bin:\$PATH; . /opt/astro/env.sh; bash /home/mmanders/job_staging/gen_dynspec.${num}.sh" >> ./gen_dynspec_exec.txt
    ((j++))
done < $FILE
