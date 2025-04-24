#!/bin/bash
#SBATCH -N 2
#SBATCH --job-nam=osu-latency
#SBATCH --ntasks-per-node=1
#SBATCH --ntasks=2
#SBATCH --mem=0
#SBATCH --time=0:1:0
#SBATCH --account=esifapps
#SBATCH --output=osu-pt2pt-latency/osu-latency_%a.out
#SBATCH --array=1-5

### Script is written to be submitted to a slurm job scheduler, basic parameters are filled in
### Script can be modified to fit other job schedulers as necessary
### We repeat the test 8 times, where each run for the OSU Micro-benchmark is iterated through 5000 times

nodes=2
PPN=1
MSG=8192
TYPE=mpi_char
RANKS=($nodes * $PPN)

for k in `seq 8`
do
srun -N $nodes -n $RANKS --ntasks-per-node=$PPN --cpu-bind=rank ./osu_latency -m 1:$MSG -i 5000 -T $TYPE
done


