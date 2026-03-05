#!/bin/bash

# user inputs
export DATA_DIR_PREFIX="/scratch/$USER/deepcam/numpy" # path to preprocessed numpy-formatted data
export OUTPUT_DIR="/scratch/$USER/DeepCAM-testing/results/$SLURM_JOB_ID" # output directory for training logs

#### BASELINE/PORTED: CAN CHANGE THESE! ####
#export STAGE_DIR_PREFIX="$TMPDIR/deepcam_staging" # If this variable is missing, no data staging occurs.
export WIREUP_METHOD="nccl-slurm"
export DGXNGPU=4           # Number of accelerators per node
export MAX_THREADS=4       # Number of data loading threads per node
####

#### BASELINE/PORTED: DO NOT CHANGE THESE! ####
export LOGGING_FREQUENCY=1 # Must be set to 1 for 'Scenario 1'
export MAX_EPOCHS=5        # Must be set to 5 for 'Scenario 1'
export LOCAL_BATCH_SIZE=8  # Per-accelerator batch size
export START_LR=0.0001     # Starting learning rate. Roughly 10X lower than target end LR.
export LR_SCHEDULE_TYPE="cosine_annealing" # Learning rate scheduler type
export LR_WARMUP_STEPS=0   # Not necessary to set for 'Scenario 1'
export OPTIMIZER="AdamW"   # Learning rate optimizer
export WEIGHT_DECAY=0.2    # L2 regularization factor - 0.2 is good for AdamW, 0.01 good for LAMB
export TRAINING_INSTANCE_SIZE=$(( $SLURM_GPUS_ON_NODE * $SLURM_NNODES )) # Number of GPUs to use during training
####

# These variables are only required if LR_SCHEDULE_TYPE="multistep"
# export LR_MILESTONES=""
# export LR_DECAY_RATE=""

# other hyperparameters
export LR_T_MAX=9000
export LR_ETA_MIN=0.0
export LR_WARMUP_FACTOR=1.
export BATCHNORM_GROUP_SIZE=1

# this is for some global parameters:
export ADDITIONAL_ARGS="--disable_tuning"

# direct io settings
export DALI_ODIRECT_ALIGNMENT=4096
export DALI_ODIRECT_LEN_ALIGNMENT=4096

# run parameters
export NEXP="${NEXP:-10}"

# system parameters
export DGXSYSTEM=$(basename $(readlink -f ${BASH_SOURCE[0]}) | sed 's/^config_//' | sed 's/\.sh$//' )
export BASE_COMP_CLOCK=1980 # obtained via nvidia-smi for SXM H100 HBM3
export BASE_MEM_CLOCK=2619  # obtained via nvidia-smi for SXM H100 HBM3

# data parameters
export SHUFFLE_MODE="global"
export DATA_FORMAT="dali-numpy"
export PRECISION_MODE="amp"
export LOCAL_VALIDATION_BATCH_SIZE=8

# staging parameter
if [ ! -z $STAGE_DIR_PREFIX ]; then 
  mkdir -p $STAGE_DIR_PREFIX
fi
export STAGE_BATCH_SIZE=8
export STAGE_MODE="global"
export STAGE_VERIFY=0
export STAGE_FULL_DATA_PER_NODE=0
export STAGE_USE_DIRECT_IO=0
#export STAGE_USE_DIRECT_IO=1 # this leads to a segfault
export STAGE_NUM_READ_WORKERS=6
export STAGE_NUM_WRITE_WORKERS=12

# misc args
export ADDITIONAL_SRUN_ARGS="--no-kill"
export ADDITIONAL_ARGS="${ADDITIONAL_ARGS} --enable_graph --disable_comm_overlap"

# number of experiments
export NEXP=1
export NUM_INSTANCES=1

# system parameters
export DGXNNODES=$SLURM_NNODES
export WALLTIME=01:00:00

# final things
if [ ! -z $STAGE_DIR_PREFIX ]; then
    mkdir -p $STAGE_DIR_PREFIX
fi