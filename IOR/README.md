# IOR

Source code: [https://github.com/hpc/ior](https://github.com/hpc/ior/releases/tag/4.0.0)

Documentation: https://ior.readthedocs.io/en/latest/

## Purpose and Description

IOR is designed to measure parallel file system I/O performance through a variety of potential APIs. This parallel program performs writes and reads to/from files and reports the resulting throughput rates. 

We use this benchmark to understand the performance of the proposed file systems.

## Licensing Requirements

IOR is licensed under GPLv2, see [here](https://github.com/hpc/ior?tab=License-1-ov-file)

## How to build

Documentation on installation [here](https://ior.readthedocs.io/en/latest/userDoc/install.html)

See example build script used to build IOR on Kestrel, `kestrel-example-build-script.sh`

## Run Definitions and Requirements

Specifics of the runs and their success criteria/acceptable thresholds

## How to run

See example run script on Kestrel, `kestrel-example-run-script.sh`
Note that this script is only an example showing a single IOR run with example IOR inputs.
For a full set of IOR inputs, see [IOR options](https://ior.readthedocs.io/en/latest/userDoc/options.html)

### Tests

List specific tests here

## Run Rules

In addition to the general ESIF-HPC-4 benchmarking rules, detail any extra benchmark-specific rules

## Benchmark test results to report and files to return

Describe what results and information the offerer should return, beyond what is detailed in the benchmarking reporting sheet
