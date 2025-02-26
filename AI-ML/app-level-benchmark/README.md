# AI-ML: MLPerf

## Purpose and Description

**Benchmark description**

MLPerf represents a suite of benchmarks that target common routines and workflows in the AI/ML space. MLPerf is maintained by [MLCommons](https://mlcommons.org), a group of AI/ML leaders from industry, government, and academia, whose goal is to deliver "open, useful measures of quality, performance and safety to help guide responsible AI development." Individual benchmarks under the MLPerf umbrella are grouped into whether they exercise "training" or "inference" workflows.

We intend to specifically run the [Graph Neural Network (GNN) benchmark](https://github.com/mlcommons/training/tree/master/graph_neural_network), which is representative of training use cases at NREL.

***Caveat***: We should discuss whether we want to proceed with GNN as a training benchmark, or if we should use an LLM inference benchmark, which may be more representative of user workloads in terms of node hours (but will not stress the system as much).
  
**Benchmark purpose**

As AI/ML techniques continue to be applied to more scientific domains on NREL HPC systems, we need an application-level benchmark to accurately capture the performance and functionality of these routines. 

*Useful links*
[Full list of MLPerf inference benchmarks](https://github.com/mlcommons/inference)
[Full list of MLPerf training benchmarks](https://github.com/mlcommons/training)
[Inference results from other institutions](https://mlcommons.org/benchmarks/inference-datacenter/)
[Training results from other institutions](https://mlcommons.org/benchmarks/training/)

## Licensing Requirements

All MLPerf benchmarks are open-source and do not have any licensing requirements.

## Other Requirements

* Containerization required.
* On Kestrel, a custom implementation of NCCL that is built with CXI-enabled libfabric is required to scale calculations beyond a single GPU node.

## How to build

This is an ongoing effort, and more details will be released here in the future. Please see [here](https://github.nrel.gov/hpc-apps/mlperf-testing) for current build instructions (the link is only accessible to internal NREL staff).

Our build instructions are based on the [GNN benchmark instructions](https://github.com/mlcommons/training/tree/master/graph_neural_network), with a custom libfabric+CXI implementation as noted in the previous section.

## Run Definitions and Requirements

A validation accuracy of 0.72 is considered a successful run. The time required to reach this accuracy is what we measure. A valid container runtime (e.g., Docker or Apptainer) is required to launch the container.

## How to run

The following Apptainer command launches a distributed training run for the GNN benchmark on Kestrel (using 24 full GPU nodes as an example):

```
export MASTER_ADDR=$(hostname)
WORLD_SIZE=$SLURM_NTASKS

srun apptainer exec \
  -B /projects:/projects \
  -B /kfs2/shared-projects/mlperf/gnn/igbh:/tools/gnn/data/igbh \
  -B /kfs2/shared-projects/mlperf/gnn/training:/tools/gnn/training/graph_neural_network \
  --nv /kfs2/shared-projects/mlperf/gnn/gnn-910cb55.sif \
  bash -c "source export_DDP_vars.sh 
          CUDA_VISIBLE_DEVICES=0,1 \"\$VENV_PYTHON\" /tools/gnn/training/graph_neural_network/dist_train_rgnn.py --path /tools/gnn/data/igbh/partitioned24 --num_nodes=$WORLD_SIZE --num_training_procs=2 --model='rgat' --dataset_size='full' --layout='CSC'"

```

### Tests

List specific tests here

## Run Rules

Before GNN training, the IGBH dataset must first be downloaded onto the host system, and "seeds" must be generated for training and validation (see [here](https://github.com/mlcommons/training/tree/master/graph_neural_network#steps-to-download-and-verify-data) for more information). Additionally, before distributed training specifically, the dataset must also be [partitioned](https://github.com/mlcommons/training/tree/master/graph_neural_network#distributed-training) according to the number of GPUs used in the job.

## Benchmark test results to report and files to return

Time required to reach 0.72 validation accuracy for a distributed training run of the GNN MLPerf benchmark.
