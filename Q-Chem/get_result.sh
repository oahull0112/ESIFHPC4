#!/bin/bash
for job_type in small medium large; do
 cd $job_type
 echo $job_type
 grep "SCF   energy" input.out | tail -1
 grep "Total job time" input.out
 cd ..
done
