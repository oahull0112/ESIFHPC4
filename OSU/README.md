# OSU Microbenchmarks

## Purpose and Description
The OSU Microbenchmark collection represents a suite of tests used to measure MPI performance in distributed computing systems. The tests include examples such as checking latency (ping-pong), measuring bandwidth rates across pairs of processes, collective tests, and other device based tests. The benchmarks are written in three different programming languages: C, Java, and Python. We use these tests to measure the performance of MPI functions on NREL HPC systems. The primary tests used are: latency, multi-bandwidth/multi-rate, all-to-all, and all-reduce. 

## Licensing Requirements

The OSU Microbenchmark collection is available under BSD licensing. Further information can be located here: https://mvapich.cse.ohio-state.edu/static/media/mvapich/LICENSE-OMB.txt

## Other Requirements
We require that two MPI distributions be tested - an MPICH variety of the vendors choice, and OpenMPI in addition. 

## How to build

We require a version of the OSU Micro-Benchmarks >= 7.4. The micro-benchmarks are downloaded from the following webpage: https://mvapich.cse.ohio-state.edu/benchmarks/ - the micro-benchmarks are compiled according to a standard 'configure' 'make' 'make install' pipeline. An example build/configuration script is located in the 'osu-scripts' directory, labelled as 'build.sh' 



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
