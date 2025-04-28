#!/bin/bash
job_name=q1
for job_type in small medium large; do
 mkdir $job_type
 cd $job_type
 cp ../../input.com .
 cp ../job.slurm .
 sed -i "s/qchem_test/$job_name.$job_type/" job.slurm
 if [ "$job_type" == "small" ]; then
  sed -i "s/6-311++G(2d,2p)/6-31G*/" input.com 
 fi
 if [ "$job_type" == "large" ]; then
  sed -i "s/6-311++G(2d,2p)/aug-cc-pvtz/" input.com
 fi
 sbatch job.slurm
 cd ..
done
