#!/bin/bash
#SBATCH --job-name="OSU - pt2pt - MBW-MR"
#SBATCH --nodes=2
#SBATCH --ntasks=208
#SBATCH --ntasks-per-node=104
#SBATCH --time=00:20:00
#SBATCH --output=osu-mbw-mr/osu-mbw-mr-results_%a.out



### Script is written to be submitted to a slurm job scheduler, basic parameters are filled in
### Script can be modified to fit other job schedulers as necessary
### We repeat the test 8 times, where each run for the OSU Micro-benchmark is iterated through 5000 times


nodes=2
PPN=104
MSG=8192
let RANKS=($nodes * $PPN)


for k in `seq 8`
do
srun -N $nodes -n $RANKS --ntasks-per-node=$PPN --cpu-bind=rank ./osu_mbw_mr -m 1:$MSG -i 5000
done
