#!/bin/bash -l
#SBATCH --account=hpcapps
#SBATCH --nodes=1
#SBATCH --tasks-per-node=32
#SBATCH --time=48:00:00
#SBATCH --gres=gpu:1
#SBATCH --mem=80G
#SBATCH --job-name=b11.small
#SBATCH --output=std.out
#SBATCH --error=std.err

module load brianqc/1.5

if [ -e /dev/nvme0n1 ]; then
 SCRATCH=$TMPDIR
 echo "This node has a local storage and will use $SCRATCH as the scratch path"
else
 SCRATCH=/scratch/$USER/$SLURM_JOB_ID
 echo "This node does not have a local storage drive and will use $SCRATCH as the scratch path"
fi

mkdir -p $SCRATCH

export QCSCRATCH=$SCRATCH
export QCLOCALSCR=$SCRATCH

jobnm=input

if [ $SLURM_JOB_NUM_NODES -gt 1 ]; then
 QCHEMOPT="-gpu -mpi -np $SLURM_NTASKS"
else
 QCHEMOPT="-gpu -nt $SLURM_NTASKS"
fi

echo Running Q-Chem with this command: qchem $QCHEMOPT $jobnm.in $jobnm.out
touch running
qchem $QCHEMOPT $jobnm.com $jobnm.out
rm running
mv job_status done

rm $SCRATCH/*
rmdir $SCRATCH


