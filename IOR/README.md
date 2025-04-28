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

These tests require MPI and parallel HDF5

## Run Definitions and Requirements

Currently we have six IOR tests, whose run commands can be found in `kestrel-example-run-script.sh`

1. POSIX Streaming, 10 GB single-segment, file-per-process
2. MPI Streaming, 100 GB single-segment, single file
3. HDF5 Streaming, 100 GB single-segment, single file
4. HDF5 Streaming, 100 GB ten-segment, single file
5. POSIX Random, 1 GB single-segment, single file
6. HDF5 Small Transfer, 1 GB ten-segment, single file

## How to run

See example run script on Kestrel, `kestrel-example-run-script.sh`
For a full set of IOR inputs, see [IOR options](https://ior.readthedocs.io/en/latest/userDoc/options.html)

## Benchmark test results to report and files to return

Todo
