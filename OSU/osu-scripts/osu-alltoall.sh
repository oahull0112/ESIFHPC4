#!/bin/bash
#SBATCH -N 8
#SBATCH --job-nam=osu-alltoall
#SBATCH --ntasks-per-node=13
#SBATCH --ntasks=104
#SBATCH --mem=0
#SBATCH --output=osu-collective-alltoall/osu-alltoall_%a.out



### Script is written to be submitted to a slurm job scheduler, basic parameters are filled in
### Script can be modified to fit other job schedulers as necessary
### We repeat the test 8 times, where each run for the OSU Micro-benchmark is iterated through 5000 times


nodes=8
PPN=13
MSG=8192
TYPE=mpi_char

let RANKS=($nodes * $PPN)


for k in `seq 8`
do
srun -N $nodes -n $RANKS --ntasks-per-node=$PPN --cpu-bind=rank ./osu_alltoall -m 1:$MSG -i 5000 -T $TYPE
done
