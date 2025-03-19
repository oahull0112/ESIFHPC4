#!/bin/bash
#SBATCH -N 8
#SBATCH --job-name=osu-collective-allreduce
#SBATCH --ntasks-per-node=96
#SBATCH --mem=0
#SBATCH --exclusive
#SBATCH --output=osu-allreduce/osu-allreduce_%a.out
#SBATCH --time=00:20:00


### Script is written to be submitted to a slurm job scheduler, basic parameters are filled in
### Script can be modified to fit other job schedulers as necessary
### We repeat the test 8 times, where each run for the OSU Micro-benchmark is iterated through 5000 times

nodes=8
PPN=96
MSG=8192
TYPE=mpi_char

let RANKS=($nodes * $PPN)


for k in `seq 8`
do
srun -N $nodes -n $RANKS --ntasks-per-node=$PPN --cpu-bind=rank ./osu_allreduce -m 1:$MSG -i 5000 -T $TYPE
done
