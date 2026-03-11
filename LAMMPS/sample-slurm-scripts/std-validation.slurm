#!/bin/bash
#SBATCH --job-name lammps-standardnode-validation
#SBATCH --nodes=1
#SBATCH --time=00:20:00
#SBATCH --tasks-per-node=64
#SBATCH --account=hpcapps
#SBATCH --exclusive


# Sample run on NLR's Kestrel machine
# Requesting 1 node with 64 tasks per node and 1 OMP thread for validation
# Required for validation
export OMP_NUM_THREADS=1

module load lammps/072225-intel-mpich

srun -n $SLURM_NTASKS lmp -in lammps.in -log lammps-${SLURM_NNODES}nodes-${SLURM_JOB_ID}.out

