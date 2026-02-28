#!/bin/bash
#SBATCH --job-name lammps-standardnode
#SBATCH --nodes=2
#SBATCH --time=00:20:00
#SBATCH --tasks-per-node=96
#SBATCH --account=hpcapps
#SBATCH --exclusive

# Sample run on NLR's Kestrel machine
# Required for baseline
export OMP_NUM_THREADS=1

module load lammps/072225-intel-mpich

srun -n $SLURM_NTASKS lmp -in lammps.in -log lammps-${SLURM_NNODES}nodes-${SLURM_JOB_ID}.out


