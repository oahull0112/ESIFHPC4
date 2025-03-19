# HPL

## Purpose and Description
HPL solves a random dense linear system in double precision arithmetic on distributed-memory. It depends on the Message Passing Interface, Basic Linear Algebra Subprograms, or the Vector Signal Image Processing Library. The software is available at the [Netlib HPL benchmark](https://www.netlib.org/benchmark/hpl/) and most vendors including ([Nvidia](https://docs.nvidia.com/nvidia-hpc-benchmarks/HPL_benchmark.html), [AMD](https://www.amd.com/en/developer/zen-software-studio/applications/pre-built-applications.html), and [Intel](https://www.intel.com/content/www/us/en/docs/onemkl/developer-guide-linux/2024-1/overview-intel-distribution-for-linpack-benchmark.html) offer hardware-optimized versions of it. The HPL benchmark assesses both the peak performance and the integrity of the system's hardware, from individual nodes to the entire system.

## Licensing Requirements

HPL is licensed per the COPYRIGHT notice in the hpl-2.3 folder.

## Other Requirements

If applicable, describe any other requirements to run the code here (e.g. ARM compatibility, needs a container, etc.)

## How to build

The source code of Netlib can be accessed here, [HPL](https://www.netlib.org/benchmark/hpl/hpl-2.3.tar.gz). Build instructions are in the INSTALL file (top directory) and are summarized below: 
1. Download and extract the source file: `$ gunzip hpl-2.3.tgz; tar -xvf hpl-2.3`.
2. Copy a make file under the setup direcotry: `$ cp setup/Make.<arch> .`.
3. Build HPL: `$ make arch=<arch>`. This should create an executable in the bin/<arch> directory called xhpl.
4. Test the executable: `$ cd bin/<arch> && mpirun -np 4 xhpl`.

Optimized binaries of HPL can be obtained from [Intel-HPL](https://www.intel.com/content/www/us/en/developer/tools/oneapi/onemkl-download.html?operatingsystem=linux&linux-install=offline) that is shipped with Intel MKL, [Zen-HPL](https://www.amd.com/en/developer/zen-software-studio/applications/pre-built-applications/zen-hpl-eula.html?filename=amd-zen-hpl-2024_10_08.tar.gz) and [Nvidia-HPL](https://developer.download.nvidia.com/compute/nvidia-hpc-benchmarks/redist/nvidia_hpc_benchmarks_mpich/linux-x86_64/nvidia_hpc_benchmarks_mpich-linux-x86_64-25.02.04-archive.tar.xz). 

## Run Definitions and Requirements

Specifics of the runs and their success criteria/acceptable thresholds

## How to run

Explain how to run the code

### Tests

List specific tests here

## Run Rules

In addition to the general ESIF-HPC-4 benchmarking rules, detail any extra benchmark-specific rules

## Benchmark test results to report and files to return

Describe what results and information the offerer should return, beyond what is detailed in the benchmarking reporting sheet
