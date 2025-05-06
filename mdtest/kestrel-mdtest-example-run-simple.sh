#!/bin/bash
#SBATCH --job-name=mdtest
#SBATCH --time=01:00:00
#SBATCH --nodes=1

export SCRATCH=/scratch/$USER/${SLURM_JOB_NAME:?}
if [ -d $SCRATCH ]
then
   rm -rf $SCRATCH
fi
mkdir $SCRATCH; cd $SCRATCH

mdtest=/path/to/mdtest

# Examples for tests 1-3 on a single node, 4 ranks

# It is important to note that the total number of ranks must be a power of 2.

# example test 1 (change ranks as needed)
exponent=20
ranks=4
I=$((2**exponent/ranks))
z=0
n=$((2**exponent/ranks))
srun --nodes=1 --ntasks=$ranks --distribution=block $mdtest -a=POSIX -C -T -r -n=$n -I=$I -z=$z -d `pwd`

# example test 2 (change ranks as needed)
exponent=20
ranks=4
I=16
z=0
n=$((2**exponent/ranks))
srun --nodes=1 --ntasks=$ranks --distribution=block $mdtest -a=POSIX -C -T -r -n=$n -I=$I -z=$z -d `pwd`

# example test 1 (change ranks as needed)
exponent=20
ranks=4
I=16
z=8
n=$((2**exponent/ranks))
srun --nodes=1 --ntasks=$ranks --distribution=block $mdtest -a=POSIX -C -T -r -n=$n -I=$I -z=$z -d `pwd`
