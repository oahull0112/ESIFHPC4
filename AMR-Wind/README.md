# AMR-Wind

## Purpose and Description

AMR-Wind is a massively parallel, block-structured adaptive-mesh, incompressible flow solver for wind turbine and wind farm simulations. It depends on the AMReX library that provides mesh data structures, mesh adaptivity, and linear solvers to handle its governing equations. This software is part the exawind ecosystem, is available [here](https://github.com/exawind/AMR-Wind). The AMR-Wind benchmark assesses how memory and network latency affects application performance on GPU-accelerated nodes and application throughput. 

## Licensing Requirements

AMR-Wind is licensed under BSD 3-clause license. The license is included in the source code repository, [LICENSE](https://github.com/Exawind/amr-wind/blob/main/LICENSE).

## How to build

AMR-Wind can be built with [`ExaWind-manager`](https://github.com/Exawind/exawind-manager) or CMake on CPUs and GPUs. Instructions for building AMR-Wind with ExaWind-manager is provided below, while instructions for building AMR-Wind with CMake can be found [here](https://exawind.github.io/amr-wind/user/build.html).

```
# Load modules
module load PrgEnv-intel
module load cray-mpich/8.1.28
module load cray-libsci/23.12.5
# Uncomment the cuda module for a GPU build 
# module load cuda 
module load cray-python

# clone ExaWind-manager
cd /scratch/${USER}
git clone --recursive https://github.com/Exawind/exawind-manager.git
cd exawind-manager

# Activate exawind-manager
export EXAWIND_MANAGER=`pwd`
source ${EXAWIND_MANAGER}/start.sh && spack-start

# Create Spack environment
mkdir environments
cd environments
spack manager create-env --name amrwind-cpu --spec 'amr-wind+mpi+netcdf %oneapi'
# Comment the above line and uncomment the line below for a GPU build
# spack manager create-env --name amrwind-gpu --spec 'amr-wind+cuda+gpu-aware-mpi cuda_arch=90  %oneapi'

# Activate the environment
spack env activate -d ${EXAWIND_MANAGER}/environments/amrwind-cpu
# Comment the above line and uncomment the line below for a GPU build
#spack env activate -d ${EXAWIND_MANAGER}/environments/amrwind-gpu

# concretize specs and dependencies
spack concretize -f

# Build software
spack -d install

```

## Run Definitions and Requirements

### Tests

This repo provides two test cases (`nrel_256/abl_godunov-256.i` and `nrel_1024/abl_godunov-1024.i`) with different grid sizes for single-node and multinode strong-scaling and throughput tests. The smaller test case, fitting within a single node’s CPUs or GPUs capacity and exposes the compute capability of the unit by reducing the effect of memory and interconnect at a node level, while the larger test case spans multiple nodes and exposes system throughout and performance bottlenecks at a system level. The Offeror should run 4-6 concurrent job instances of the benchmark on the target system to control anytime variabilities and unexpected performance behaviors under load. The application throughput can be computed as follows: `throughput = allocation factor * node-class count) / (number of nodes * runtime)`.

## How to run

To run AMR-Wind CPUs, you need MPI support, Slurm inputs including number of nodes, total number of tasks and number of tasks per node and input and executable files. The benchmark results can be obtained with Slurm:
```
srun -N <number of nodes> -n <total number of tasks> --ntasks-per-node=<number of tasks per node> <path to build directory>/amr_wind <input file> >& <output file>.log

```
To run AMR-Wind on GPUs, GPU-Aware MPI is required for an optimal performance. Additionally, inputs such as number of nodes, total number of MPI tasks, total number of tasks per node, and total number of GPUs per node are required. The benchmark results can be obtained with Slurm:
```
srun -N <number of nodes> -n <total number of GPUs> --ntasks-per-node=<number of GPUs per node> --gpus-per-node=<number of GPUs per node> <path to build directory>/amr_wind <input file> >& <output file>.log`

```

The offeror should reveal any potential for performance optimization on the target system that provides an optimal task configuration by running As-is and Optimized cases. On CPU nodes, the As-is case will saturate all available cores per node to establish baseline performance and expose potential computational bottlenecks and memory-related latency issues. The Optimized case will saturate at least 70% of cores per node and will include configurations exploring strategies to identify opportunities for reducing latency. On GPU nodes, the As-is case will saturate all GPUs per node to evaluate GPU compute and memory bandwidth performance. The Optimized case will saturate all GPUs and CPU threads per node, along with optimizations focusing on minimizing data transfers and leveraging GPU-specific memory features, aiming to reveal opportunities for reducing end-to-end latency.

### How to validate

Validating output in AMR-Wind requires checking the absolute and relative error between the norms of the two output directories at the 1000<sup>th</sup> timestep for different output variables. Run the following command to validate results:

```
./${BASE}/submods/amrex/Tools/Plotfile/fcompare plt01000 plt01000.ref-<grid size>

```
where `plt01000.ref-<grid size>` is the reference output directory, being compared against `plt01000` generated from the Offeror's runs. The reference output directories (`nrel_256/plt01000` and `nrel_1024/plt01000`) for validation of each of the two cases being considered for this benchmark shall be available in this repo.

## Run Rules

* The input files cause writing of large output every 100 timesteps and writes checkpoint data every 200 steps, with the entire case running for 1000 timesteps. An Offeror may modify the input files only with an accompanying justification for the change in the Text response.
* The smaller benchmark (`nrel_256/abl_godunov-256.i`) might not scale across compute units within a node, which limits demonstration of future hardware capabilities. In such a case, the offeror may use the larger benchmark (`nrel_1024/abl_godunov-1024.i`) for a single-node test with an accompanying justification for the change in the Text response if the data fits within the available GPU memory and there is sufficient memory bandwidth.
* Any optimizations would be allowed in the code, build and task configuration as long as the offeror would provide a high-level description of the optimization techniques used and their impact on performance in the Text response.
* The offeror could use an AMRv3.4.0 or later version with GNU, Intel, or accelerator-specific compilers and libraries.

## Benchmark test results to report and files to return

The following AMR-Wind-specific information should be provided:

* For reporting scaling and throughput studies, use the harmonic mean of the `Time spent in Evolve` wall-clock times from output logs in the Spreadsheet (`report/amr-wind_benchmark.csv`).
* As part of the File response, please return job-scripts and their outputs, log files, and plt01000 folders from each run.
* Include in the Text response validation data with validation results in a table and a high-level description of any optimization done. If results vary by more than the 1e-3 reference tolerance for validation, please also report the maximum difference of results against the reference results with a justification as to why the results should be considered correct.