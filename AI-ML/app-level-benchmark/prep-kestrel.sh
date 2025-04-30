#!/bin/bash
#SBATCH -A esifapps
#SBATCH -p shared
#SBATCH -t 04:00:00
#SBATCH --mem=16G
#SBATCH -n 1
#SBATCH --job-name=prep
#SBATCH -o %j-%x.out

# Create mamba env
ml mamba
eval "$(conda shell.bash hook)"
mamba create --prefix=./pytorch-3dunet-env python
conda activate ./pytorch-3dunet-env
pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
pip3 install git+https://github.com/NVIDIA/dllogger#egg=dllogger requests nibabel scipy https://github.com/mlcommons/logging/archive/refs/tags/1.1.0-rc4.zip

# Download KiTS19 data
mkdir raw-data-dir
cd raw-data-dir
git clone https://github.com/neheller/kits19
cd kits19
python3 -m starter_code.get_imaging
cd ../..

# Preprocess data
git clone git@github.com:mlcommons/training.git
cd training/retired_benchmarks/unet3d/pytorch
sed -i 's|/results|./results|' main.py
sed -i 's|DATASET_DIR="/data"|DATASET_DIR="./data"|' run_and_time.sh
sed -i "s/EXCLUDED_CASES = \[\]/EXCLUDED_CASES = \[53\]/" preprocess_dataset.py
sed -i 's|signal.gaussian|signal.windows.gaussian|' runtime/inference.py
mkdir data
mkdir results
python3 preprocess_dataset.py --data_dir ../../../../raw-data-dir/kits19/data --results_dir ./data