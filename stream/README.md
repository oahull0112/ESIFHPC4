# Stream

## Purpose and Description

- stream.[c,f] are the standard memory bandwith test.
- pstream.c is a variation of stream designed to test the abillity to get good processor affinity.
- mstream.cu and stream.cu are GPU versions of stream.c

## Licensing Requirements

Open source

## Other Requirements

mstream.cu and stream.cu require GPUs

## How to build

Build procedures are described in the source directories.

## Run Definitions and Requirements

There are no criteria/acceptable thresholds except for pstream.c It must show that
there is good affinity mapping with no cores oversubscribed.

## How to run

Run procedures are described in the source directories.

### Tests

stream.c - standard stream bechnmark
stream.f - standard stream bechnmark
pstream.c - affinity version of stream benchmark
stream.cu - GPU stream
mstream.cu - MPI version of GPU stream

## Run Rules

Run procedures are described in the source directories.


## Benchmark test results to report and files to return

Describe what results and information the offerer should return, beyond what is detailed in the benchmarking reporting sheet
