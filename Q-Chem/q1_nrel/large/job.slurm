#!/bin/bash -l
#SBATCH --account=hpcapps
#SBATCH --nodes=1
#SBATCH --tasks-per-node=104
#SBATCH --time=48:00:00
#SBATCH --job-name=q1.large
#SBATCH --exclusive
#SBATCH --output=std.out
#SBATCH --error=std.err

module load q-chem/6.2

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
 QCHEMOPT="-mpi -np $SLURM_NTASKS"
else
 QCHEMOPT="-nt $SLURM_NTASKS"
fi

echo Running Q-Chem with this command: qchem $QCHEMOPT $jobnm.com $jobnm.out
touch running
qchem $QCHEMOPT $jobnm.com $jobnm.out
rm running
mv job_status done

rm $SCRATCH/*
rmdir $SCRATCH


