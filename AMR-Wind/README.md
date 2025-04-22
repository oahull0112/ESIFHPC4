# AMR-Wind

## Purpose and Description

AMR-Wind is a massively parallel, block-structured adaptive-mesh, incompressible flow solver for wind turbine and wind farm simulations. It depends on the AMReX library that provides mesh data structures, mesh adaptivity, and linear solvers to handle its governing equations. This software is part the exawind ecosystem, is available [here](https://github.com/exawind/AMR-Wind). The AMR-Wind benchmark assesses how latency affects application performance on GPU-accelerated nodes. 

## Licensing Requirements

AMR-Wind is licensed under BSD 3-clause license. The license is included in the source code repository, [LICENSE](https://github.com/Exawind/amr-wind/blob/main/LICENSE).

## How to build

AMR-Wind can be built with [`ExaWind-manager`](https://github.com/Exawind/exawind-manager) or CMake on GPUs. Instructions for building AMR-Wind with ExaWind-manager is provided below, while instructions for building AMR-Wind with CMake can be found [here](https://exawind.github.io/amr-wind/user/build.html).

```
# GNU
module load PrgEnv-gnu
module load cray-mpich/8.1.28
module load  cray-libsci/23.12.5
module load cuda
module load cray-python

# clone ExaWind-manager
cd /scratch/${USER}
git clone --recursive https://github.com/Exawind/exawind-manager.git
cd exawind-manager

# Activate exawind-manager
export EXAWIND_MANAGER=`pwd`
source ${EXAWIND_MANAGER}/start.sh && spack-start

# Create Spack environment and change the software versions if needed
mkdir environments
cd environments
spack manager create-env --name amr_wind-gpu --spec 'amr-wind+cuda+gpu-aware-mpi cuda_arch=90  %gcc'

# Activate the environment
spack env activate -d ${EXAWIND_MANAGER}/environments/amr-wind

# concretize specs and dependencies
spack concretize -f

# Build software
spack -d install

```

## Run Definitions and Requirements

Validating output in AMR-Wind requires checking the absolute and relative error between the norms of the two output directories at the 1000<sup>th</sup> timestep for different output variables. To validate results, for the smaller grid problem, run:

```
./${BASE}/submods/amrex/Tools/Plotfile/fcompare plt01000 plt01000.ref-<grid size>

```
where `plt01000.ref-<grid size>` is the reference output directory, being compared against `plt01000` generated from the Offeror's runs. The reference output directories for validation of each of the two cases being considered for this
benchmark shall beavailable in this repo.

## How to run

To run AMR-Wind, you need GPU-Aware MPI support for an optimal performance. The required input is number of nodes, total number of MPI ranks, total number of ranks per node, and total number of GPUs per node. The benchmark results can be obtained with Slurm: 
`srun -N <number of nodes> -n <total number of GPUs> --ntasks-per-node=<number of GPUs per node> --cpu-bind=cores --gpus-per-node=<number of GPUs per node> <path to build directory>/amr_wind <input file> >& <output file>.log`

### Tests

This repo provides two test cases with different grid sizes for single-node and multinode strong scaling tests. The smaller test case, fitting within a single node's GPU capacity (from one to the maximum), measures inter-node latency, while the larger test case, spanning multiple nodes, measures intra-node latency.

## Run Rules

The input files cause writing of large output every 100 timesteps and writes checkpoint data every 200 steps, with the entire case running for 1000 timesteps. An Offeror may modify the input files only with an accompanying justification for the change in the Text response.

## Benchmark test results to report and files to return

The following AMR-Wind-specific information should be provided:

* For scaling studies, the wall time to be reported is the sum of the wallclock times that are reported in the InitData and Evolve row at the end of output log files should be entered into the Spreadsheet response.

* As part of the File response, please return job-scripts and their outputs, log files, and plt01000 folders from each run.

* Include in the Text response validation data, with validation results in a table. If results vary by more than the 1e-3 reference tolerance, please also report the maximum difference of results against the reference results with a justification as to why the results should be considered correct.
