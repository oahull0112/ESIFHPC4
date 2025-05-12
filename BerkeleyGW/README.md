This benchmark for NREL ESIF-HPC4 adapts the Optical Properties of Materials benchmark from the [NERSC-10 Benchmark Suite](https://www.nersc.gov/systems/nersc-10/benchmarks). 

Any available ESIF-HPC4 benchmark run rules should be reviewed before running this benchmark.

Note, in particular:
- Any broader ESIF-HPC4 run rules apply to this benchmark except where explicitly noted within this README.
- Responses to the ESIF-HPC4 RFP including this benchmark should include the performance metrics discussed below. The reference times included for this benchmark were run by NREL on Kestrel. 
- This benchmark defines multiple problem sizes: small, medium, and large to allow testing across a range of resource sizes. 
- This benchmark can be run on GPU or CPU nodes, however GPU nodes are the preferred node type for this application due to the substantially lower run times required. 

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

For the series of input problems distributed with this benchmark, the computational complexity of Epsilon increases quartically, $O(N^4)$, with the number of atoms.

## 0.2 Parallel decomposition

Epsilon uses a two-tier MPI Inter- and Intra-pool decomposition to exploit the available parallelism. 

# 1. BerkeleyGW Code Access and Compilation Details

The instructions below can be used to build BerkeleyGW for the GPU-accelerated nodes of NREL's Kestrel system. This example is not intended to prescribe how to build BerkeleyGW; some modifications may be needed to build BerkeleyGW for other target architectures.

## 1.0 Build Environment

Before beginning, it is convenient to store the path to directory that contains this README.md file in the E4_BGW variable:

```
E4_BGW=$(pwd)
```

BerkeleyGW depends on multiple external software packages, and has been tested extensively with various configurations. BerkeleyGW might perform better when using optimized math libraries, for example by using ELPA instead of ScaLAPACK for matrix diagonalization. 

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

On NREL's Kestrel machine, BerkeleyGW can be run using the BerkeleyGW module. This module can be accessed for either CPU or GPU nodes by logging in via a CPU or GPU log-in node (https://nrel.github.io/HPC/Documentation/Systems/Kestrel/) and loading the module:
```
module load berkeleygw
```

If you decide to build your own version of BerkeleyGW, the latest version of BerkeleyGW can be downloaded from the BerkeleyGW website: https://berkeleygw.org/download/. The current release (4.0 at the time of this writing) is recommend for use due to the many performance improvements implemented as compared to the 3.x versions. Enter the E4_BGW directory, then download and untar the BerkeleyGW source code:
```
cd $E4_BGW
wget https://app.box.com/shared/static/22edl07muvhfnd900tnctsjjftbtcqc4.gz
tar -xvf BerkeleyGW-4.0.gz
```

## 1.2 Configuring BerkeleyGW

If you decide to build your own version of BerkeleyGW, the BerkeleyGW build system is based on `make` and requires manual configuration by editing an architecture-specific makefile named `arch.mk`. Example `arch.mk` files for various supercomputers are provided in the `$E4_BGW/BerkeleyGW/config` directory.
* Select the file most closely related to the target environment and copy it. For example:
```bash
cd $E4_BGW/BerkeleyGW
cp config/perlmutter.nersc.gov-nvhpc-openacc.mk arch.mk
```
* Edit `arch.mk` to fit your needs, for example, by adding the appropriate library paths.
Refer to the [BerkeleyGW manual](http://manual.berkeleygw.org/3.0/compilation-flags/) for more options.

## 1.3 Compiling BerkeleyGW

Stay in the `BerkeleyGW` directory to compile the various BerkeleyGW modules. (Many modules will be compiled, but this benchmark only uses Epsilon.) The following  command will generate the complex (`cplx`) version of the code.
```
make -j cplx 
```
After compilation, the excutable (`epsilon.cplx.x`) will be in the source directory. Symbolic links with the same name will be in the `BerkeleyGW/bin` directory.

# 2. Running the BerkeleyGW benchmark

The directory contains three problem sizes:

| Problem Size | Atoms             |
| ------------ | ----------------- |
| small        | Si<sub> 214</sub> |
| medium       | Si<sub> 510</sub> |
| large        | Si<sub> 998</sub> |
Each problem simulates a silicon divacancy defect embedded in a series of progressively larger supercells. The small, medium, and large problems are provided to facilitate testing and profiling across a wide range of numbers of resources. 

## 2.1 Download wave-function data

Each problem requires several data files that must be downloaded prior to running the benchmarks. The largest of these are the `.WFN` (wave-function) files. These files are large and are provided separately to avoid accidental download. The workflow for each problem size can be executed using only the corresponding data files. (To run the medium workflow, only the medium files need to be downloaded.)

The data files should be downloaded to the `Si_WFN_folder` directory. Note that it may be possible to reduce I/O time by moving the `Si_WFN_folder` to a high performance filesystem prior to the download and distributing the directory over multiple disks ("striping"). Explicit striping instructions are not provided here because the commands and optimal settings are not transferable to other filesystems.

The files are currently available from the [NERSC BerkeleyGW Benchmark data portal](https://portal.nersc.gov/project/m888/nersc10/benchmark_data/BGW_input) and can be retreived using `wget`. The `wget_WFN.sh` script is provided to simplify the download process:
```
$ cd Si_WFN_folder
$ ./wget_WFN.sh --help
| Usage: wget_WFN.sh <size>
| Allowed sizes: 
|  [ small     (   3 GB ), 
|    medium    (  18 GB ), 
|    large     (  71 GB ) ]
```

## 2.2 Update site-specific files

Enter the `$E4_BGW/benchmark` folder and edit the `site_path_config.sh` script to specify the location of required libraries, BerkeleyGW executable (`bin/`) folder and folders with large I/O files. In particular:
* `HDF_LIBPATH=` path to the location of libraries, if any.
* `BGW_DIR=` path to epsilon.cplx.x (i.e., the `BerkeleyGW/bin` directory created in the previous section).
* `Si_WFN_folder=` path to large I/O downloaded files (`$Si_WFN_folder/` from the previous section).

## 2.3 Submit

Each problem size has its own subdirectory within `$E4_BGW/benchmark`. Each of those directories contains the input files needed for Epsilon, and a submit script suitable for NREL's Kestrel system. For example, to run the medium size Epsilon calculation on Kestrel, after having appropriately modified `berkeleygw-workflow/benchmark/site_path_config.sh`, do:
```
cd $E4_BGW/benchmark/medium_Si510/
sbatch run_epsilon_Si510.sh 
```

Note that a script called stripe_large has been included that on Kestrel allows striping of a particular directory. This script is called by each run_epsilon_* Slurm script and should be removed if alternative striping is used. 

Each Kestrel GPU node has 4 NVIDIA H100 GPUs and dual socket AMD Genoa CPUs. The parallel configuration for all runs on Kestrel used 4 MPI tasks per node, and each MPI task uses 1 GPU and 16 CPU cores. To run on systems different than Kestrel, modify the run scripts to reflect the hardware specifics of the architecture of interest. For Epsilon, there are no constraints on the number of MPI tasks that may be used. The input file (`epsion.inp`) may not be modified **except** to optimize the maximum GPU memory per MPI rank (in GB) to use for Epsilon's chi summation phase using the `max_mem_nv_block_algo` flag in `epsion.inp`. This flag can have a strong influence on time to solution: more memory typically improves performance. Half the device memory is a reasonable initial guess.

The `run_epsilon_*` scripts will generate the `BGW_EPSILON_$SLURM_JOBID` folder where the calculations will run, and all output files will be written to this directory. The `$SLURM_JOB_ID` variable will be defined by SLURM when the job is submitted. The main results, including timing information, are directed to standard output, which will be directed to `BGW_EPSILON_$SLURM_JOBID.out`.

# 3. Results

The run scripts in the benchmark directories will write standard output to `BGW_EPSILON_$SLURM_JOBID.out`, with `$SLURM_JOBID` being the job id assigned to your job by Slurm at submission. Each stdout file contains the information needed to determine the programs' correctness and performance for the Epsilon benchmark. 

## 3.1 Correctness & Timing

Correctness can be verified using the `benchmark/BGW_validate.sh` script, which compares values from the output to their expected output. The result of the validation test is printed on the first line of the script output. For example:
```
$ ../BGW_validate.sh: test output correctness for the ESIF-HPC4 BerkeleyGW benchmark.
|  Usage: BGW_validate.sh <app> <size> <output_file>
|  Allowed apps: [ epsilon ]
|  Allowed sizes: [ small, medium, large ]
|  Example: BGW_validate.sh epsilon small BGW_EPSILON.out

$ ../BGW_validate.sh: epsilon small BGW_EPSILON.out
|  Testing epsilon small
|  Validation:    PASSED
|  Total Time:     62.45
|  I/O Time:        5.33
|  Benchmark Time: 57.12
```
In addition, these scripts will print several performance results for the job:
* Total Time corresponds to the full duration of the executed job.
* I/O Time is the time spent writing data to disk.
* Benchmark Time is computed by subtracting the I/O times from the Total Time.

## 3.2 Performance on Kestrel

The sample data in the table below are measured runtimes from NREL's Kestrel GPU partition. Kestrel's GPU nodes have one dual socket AMD Genoa CPU with 64-core processors (128 cores total) and four NVIDIA H100 SXM GPUs with 80 GB memory. Each job used four MPI tasks per node, each with one GPU and 16 cores. BerkeleyGW was built using PrgEnv-nvhpc.

| Problem Size | GPUs Used | Epsilon Total Time (seconds) | Epsilon I/O Time (seconds) | Epsilon Benchmark Time (seconds) |
|--------------|-----------|------------------------------|----------------------------|----------------------------------|
| small        | 1         | 455                          | 16                         | 439                              |
| small        | 2         | 228                          | 21                         | 207                              |
| small        | 4         | 121                          | 15                         | 106                              |
| small        | 8         | 70                           | 14                         | 55                               |
| small        | 16        | 46                           | 20                         | 26                               |
| medium       | 8         | 1172                         | 134                        | 1037                             |
| medium       | 16        | 607                          | 69                         | 538                              |
| medium       | 32        | 366                          | 41                         | 325                              |
| medium       | 64        | 261                          | 35                         | 226                              |

## 3.3 Reporting

For any problem size, benchmark results should include the Benchmark Time and I/O Time. The hardware configuration (i.e. the number of elements from each pool of computational resources) needed to achieve the estimated timings must also be provided. For example, if the anticipated compute system includes more than one type of compute node, then report the number and type of nodes used to run each stage of the workflow. If the target system enables disaggregation/composability, a finer grained resource list is needed. 

If providing run files, include all the build environment, source and makefiles used to build on the target platform, and input files and runscripts. Include all standard output files.

