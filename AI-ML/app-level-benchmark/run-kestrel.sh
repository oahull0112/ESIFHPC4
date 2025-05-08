#!/bin/bash
#SBATCH -A esifapps
#SBATCH -p gpu-h100s
#SBATCH -t 04:00:00
#SBATCH --mem=80G
#SBATCH -n 32
#SBATCH --gres=gpu:1
#SBATCH --job-name=3DUNet
#SBATCH -o %j-%x.out

### !! Only run this script AFTER running prep-kestrel.sh !! ###

eval "$(conda shell.bash hook)"
conda activate ./pytorch-3dunet-env
cd training/retired_benchmarks/unet3d/pytorch

bash run_and_time.sh 0
