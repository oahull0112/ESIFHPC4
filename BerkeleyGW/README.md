This benchmark for ESIF-HPC4 adapts the Optical Properties of Materials benchmark
from the [NERSC-10 Benchmark Suite](https://www.nersc.gov/systems/nersc-10/benchmarks). 

The ESIF-HPC4 benchmark run rules should be reviewed before running this benchmark.

Note, in particular:
- The ESIF-HPC4 run rules apply to this benchmark except where explicitly noted within this README.
- The run rules define "baseline", "ported" and "optimized" categories of performance optimization.
- Responses to the ESIF-HPC4 RFP should include performance metrics for the "baseline" category for the medium benchmark, as described below; results for the "ported" and "optimized" categories are optional. The reference times included in this benchmark were run by NREL on Kestrel. 
- This benchmark defines multiple problem sizes: medium and small. The small benchmark is optional and may be useful for initial testing. 


# 0. Workflow Overview

Predicting optical properties of materials and nanostructures is a key step toward developing future energy conversion materials and electronic devices. The BerkeleyGW code is widely used for this type of simulation workflow. A typical workflow takes some mean field-related quantities from DFT-based codes such as PARATEC, Abinit, PARSEC, Quantum ESPRESSO, OCTOPUS and SIESTA. Then BerkeleyGW's Epsilon module computes the material's dielectric function. The Sigma module uses the output of the preceding steps to compute the electronic self energy. Two other modules, Kernel and Absorption, can build upon the output from Epsilon and Sigma to calculate the electron-hole interactions and neutral optical excitation properties.

This benchmark focuses on the Epsilon stage of the workflow; the DFT, Sigma, Kernel, and Absorbtion stages are not included in this benchmark. 

The BerkeleyGW code is mostly written primarily in Fortran, with some C and C++,
and contains about 100,000 lines of code. It is parallelized using MPI and OpenMP on the CPU, and OpenACC/OpenMP-target constructs on GPUs. The project website is https://berkeleygw.org, and its documentation is available from http://manual.berkeleygw.org/3.0/. A paper derscribing the details of its implementation is published here: https://www.sciencedirect.com/science/article/pii/S0010465511003912?via%3Dihub. BerkeleyGW is distributed under the Berkeley Software Distribution (BSD) license. Please see the [license.txt](BerkeleyGW/license.txt) and [Copyright.txt](BerkeleyGW/Copyright.txt) files for more details.

## 0.1 Epsilon 

The Epsilon module for the GPP approach has three main computational kernels:
* MTXEL: Matrix elements computation
* CHI-0: Static Polarizability
* Inversion: Matrix inversion of the static polarizability (LU decomposition + triangular inversion)

For the series of input problems distributed with this benchmark,
the computational complexity of Epsilon
increases quartically,$`O(N^4)`$, with the number of atoms.

## 0.2 Parallel decomposition

Epsilon uses a two-tier MPI Inter- and Intra-pool decomposition to exploit the available parallelism. 

# 1. BerkeleyGW Code Access and Compilation Details

The instructions below can be used to build BerkeleyGW for the GPU-accelerated nodes of NERSC's Perlmutter system (AMD EPYC + NVIDIA Ampere). This example is not intended to prescribe how to build BerkeleyGW; some modifications may be needed to build BerkeleyGW for other target architectures.

## 1.0 Build Environment

Before beginning, it is convenent to store the path to directory that contains this README.md  file in the E4_BGW variable:
```
E4_BGW=$(pwd)
```

BerkeleyGW depends on multiple external software packages, and has been tested extensively with various configurations.

| Category | Dependency<br>Level | Tested Packages |
|---       |---                  |---                 |
| Operating system | required   | Linux, AIX, MacOS  |
| Fortran compiler | required   | pgf90, ifort, gfortran, g95, openf90, sunf90, pathf90,<br>crayftn, af90 (Absoft), nagfor, xlf90 (experimental) |
| C compiler       | required   | pgcc, icc,  gcc, opencc, pathcc, craycc, clang   |
| C++ compilers    | required   | pgCC, icpc, g++, openCC, pathCC, crayCC, clang++ |
| FFT              | required   | FFTW versions 3.3.x |
| LAPACK/BLAS      | required   | NetLib, ATLAS, Intel MKL, ACML, Cray LibSci      |
| MPI              | optional   | OpenMPI, MPICH1, MPICH2, MVAPICH2, Intel MPI     |
| ScaLAPACK/BLACS  | optional<br>(required if MPI is used) |  NetLib, Cray LibSci, Intel MKL, AMD |

On Kestrel, these libraries can be loaded by module commands:
```bash
module swap PrgEnv-gnu PrgEnv-nvhpc
module load cray-hdf5-parallel
module load cray-fftw
module load cray-libsci
module load python 
```

## 1.1 Downloading BerkeleyGW


## 1.2 Configuring BerkeleyGW


## 1.3 Compiling BerkeleyGW
Stay in the `BerkeleyGW-master` directory to compile the various BerkeleyGW modules. (Many modules will be compiled, but this benchmark only uses Epsilon.) The following  command will generate the complex (`cplx`) version of the code.
```
make -j cplx 
```
After compilation, the excutable (`epsilon.cplx.x`) will be in the source directory. Symbolic links with the same name will be in the `BerkeleyGW-master/bin` directory.

# 2. Running the BerkeleyGW benchmark


## 2.1 Download wave-function data

Each problem requires several data files that must be downloaded prior to running the benchmarks. The largest of these are the `.WFN` (wave-function) files. These files are large and are provided separately to avoid accidental download. The workflow for each problem size can be executed using only the corresponding data files. (To run the medium workflow, only the medium files need be downloaded.)

The data files should be downloaded to the `Si_WFN_folder` directory. Note that it may be possible to reduce I/O time by moving the `Si_WFN_folder` to a high performance filesystem prior to the download, and distributing the directory over multiple disks ("striping"). Explicit striping instructions are not provided here because the commands and optimal settings are not transferable to other filesystems.

The files are available from ...

## 2.2 Update site-specific files


## 2.3 Submit

Each problem size has its own subdirectory within `$E4_BGW/benchmark`. Each of those directories contains the input files needed for Epsilon, and a submit script suitable for NREL's Kestrel system. For example, to run the medium size Epsilon calculation on Kestrel, after having appropriately modified `berkeleygw-workflow/benchmark/site_path_config.sh`, do:
```
cd $E4_BGW/benchmark/medium_Si510/
sbatch run_epsilon_Si510.sh 
```


# 3. Results


## 3.1 Correctness & Timing


## 3.2 Performance on Kestrel

The sample data in the table below are measured runtimes from NREL's Kestrel GPU partition. Kestrel's GPU nodes have one Dual socket AMD Genoa CPU with 64-core processors (128 cores total) and four NVIDIA H100 SXM GPUs with 80 GB memory. Each job used four MPI tasks per node, each with one GPU and 16 cores. 

| Problem<br>Size | Nodes<br>Used |     | Epsilon<br>Total Time<br>(Seconds) | Epsilon<br>I/O Time<br>(Seconds) | Epsilon<br>Benchmark Time<br>(Seconds) |
| --------------- | ------------- | --- | ---------------------------------- | -------------------------------- | -------------------------------------- |


## 3.3 Reporting

Benchmark results should include the Benchmark Time and I/O Time for the medium problem size (Si-510). The hardware configuration (i.e. the number of elements from each pool of computational resources) needed to achieve the estimated timings must also be provided. For example, if the target compute system includes more than one type of compute node, then report the number and type of nodes used to run each stage of the workflow. If the target system enables disaggregation/composability, a finer grained resource list is needed. NERSC has previously described such a procedure in detail in their NERSC10 benchmark suite in the [Workflow-SSI document]( https://gitlab.com/NERSC/N10-benchmarks/run-rules-and-ssi/-/blob/main/Workflow_SSI.pdf ).

For the electronic submission, include all the source and makefiles used to build on the target platform and input files and runscripts. Include all standard output files.

