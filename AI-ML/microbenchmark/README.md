# AI-ML: GPU-GPU Collective Test

## Purpose and Description

This benchmark is intended to stress GPU-GPU (or accelerator-accelerator) network communication through the use of an appropriate collective communication library (CCL). The exact implementation of this benchmark depends on the target's hardware architecture. For example, because Kestrel (NREL's current flagship system) hosts NVIDIA H100 GPUs, we implement AllReduce and AllGather tests using [NCCL](https://developer.nvidia.com/nccl). Running AllReduce and AllGather on any equivalent CCL for other hardware is satisfactory for this benchmark.

## Licensing Requirements

None.

## Other Requirements

None.

## How to build

See the Slurm script [`build_nccl_cxi.sh`](./build_nccl_cxi.sh) for instructions on how to build NCCL with CXI-enabled libfabric on Kestrel. Note the use of a custom Open Fabrics Initiative (OFI) plugin to enable the use of HPE Slingshot communication protocols, which is needed because NCCL assumes an InfiniBand interconnect by default. This step may not be necessary depending on your hardware and network configuration.

## Run Definitions and Requirements

On Kestrel, the maximum out-of-place bus bandwidth is ~45 GB/s as measured by NCCL AllReduce and ~42 GB/s as measured by NCCL AllGather. See "Benchmark test results to report and files to return" below for reference.

## How to run

See [`run_nccl_cxi.sh`](./run_nccl_cxi.sh) for an example submission script of running `all_reduce_perf` and `all_gather_perf` from the official [nccl-tests](https://github.com/NVIDIA/nccl-tests/tree/master) repository.

### Tests

Running multi-GPU AllReduce and AllGather collectives across multiple nodes satisfies this benchmark.

```
all_reduce_perf -b 8 -e 4G -f 2
```

**Options:**
- `-b`: Minumum size in bytes
- `-e`: Maximum size in bytes
- `-f`: Increment factor


## Run Rules


## Benchmark test results to report and files to return

### AllReduce reference
Below are AllReduce results from Kestrel when running [`all_reduce_perf`](https://github.com/NVIDIA/nccl-tests/tree/master) built with the [custom NCCL+CXI plugin](https://github.com/NERSC/nccl-ofi-plugin) (described in 'How to build') to enable the use of the HPE Slingshot interconnect. This example output represents a run of 64 GPU devices across 16 nodes:

```
#
#                                                              out-of-place                       in-place
#       size         count      type   redop    root     time   algbw   busbw #wrong     time   algbw   busbw #wrong
#        (B)    (elements)                               (us)  (GB/s)  (GB/s)            (us)  (GB/s)  (GB/s)
           8             2     float     sum      -1    59.83    0.00    0.00      0    50.15    0.00    0.00      0
          16             4     float     sum      -1    48.52    0.00    0.00      0    48.03    0.00    0.00      0
          32             8     float     sum      -1    49.18    0.00    0.00      0    48.92    0.00    0.00      0
          64            16     float     sum      -1    57.47    0.00    0.00      0    56.21    0.00    0.00      0
         128            32     float     sum      -1    56.61    0.00    0.00      0    57.15    0.00    0.00      0
         256            64     float     sum      -1    58.16    0.00    0.01      0    57.66    0.00    0.01      0
         512           128     float     sum      -1    60.88    0.01    0.02      0    61.13    0.01    0.02      0
        1024           256     float     sum      -1    68.15    0.02    0.03      0    72.95    0.01    0.03      0
        2048           512     float     sum      -1    76.24    0.03    0.05      0    71.22    0.03    0.06      0
        4096          1024     float     sum      -1    101.5    0.04    0.08      0    72.00    0.06    0.11      0
        8192          2048     float     sum      -1    92.31    0.09    0.17      0    292.2    0.03    0.06      0
       16384          4096     float     sum      -1    108.3    0.15    0.30      0    137.8    0.12    0.23      0
       32768          8192     float     sum      -1    174.0    0.19    0.37      0    102.1    0.32    0.63      0
       65536         16384     float     sum      -1    185.4    0.35    0.70      0    160.0    0.41    0.81      0
      131072         32768     float     sum      -1    482.6    0.27    0.53      0    235.5    0.56    1.10      0
      262144         65536     float     sum      -1    309.3    0.85    1.67      0    314.1    0.83    1.64      0
      524288        131072     float     sum      -1    835.3    0.63    1.24      0    462.2    1.13    2.23      0
     1048576        262144     float     sum      -1   1426.9    0.73    1.45      0   1380.6    0.76    1.50      0
     2097152        524288     float     sum      -1   2987.6    0.70    1.38      0   2825.5    0.74    1.46      0
     4194304       1048576     float     sum      -1   2305.9    1.82    3.58      0   2646.1    1.59    3.12      0
     8388608       2097152     float     sum      -1   2419.0    3.47    6.83      0   2418.1    3.47    6.83      0
    16777216       4194304     float     sum      -1   2202.9    7.62   14.99      0   1750.6    9.58   18.87      0
    33554432       8388608     float     sum      -1   2973.4   11.29   22.22      0   2636.4   12.73   25.06      0
    67108864      16777216     float     sum      -1   3152.7   21.29   41.91      0   3175.2   21.14   41.61      0
   134217728      33554432     float     sum      -1   6239.5   21.51   42.35      0   6235.4   21.53   42.38      0
   268435456      67108864     float     sum      -1    12425   21.60   42.53      0    12427   21.60   42.53      0
   536870912     134217728     float     sum      -1    23352   22.99   45.26      0    23229   23.11   45.50      0
  1073741824     268435456     float     sum      -1    49081   21.88   43.07      0    46386   23.15   45.57      0
  2147483648     536870912     float     sum      -1    92587   23.19   45.66      0    92579   23.20   45.67      0
  4294967296    1073741824     float     sum      -1   184959   23.22   45.72      0   185005   23.22   45.71      0
```

### AllGather reference

```
#
#                                                              out-of-place                       in-place
#       size         count      type   redop    root     time   algbw   busbw #wrong     time   algbw   busbw #wrong
#        (B)    (elements)                               (us)  (GB/s)  (GB/s)            (us)  (GB/s)  (GB/s)
           0             0     float    none      -1     0.27    0.00    0.00      0     0.18    0.00    0.00      0
           0             0     float    none      -1     0.17    0.00    0.00      0     0.17    0.00    0.00      0
           0             0     float    none      -1     0.17    0.00    0.00      0     0.17    0.00    0.00      0
           0             0     float    none      -1     0.17    0.00    0.00      0     0.17    0.00    0.00      0
           0             0     float    none      -1     0.17    0.00    0.00      0     0.17    0.00    0.00      0
           0             0     float    none      -1     0.17    0.00    0.00      0     0.17    0.00    0.00      0
           0             0     float    none      -1     0.17    0.00    0.00      0     0.17    0.00    0.00      0
        1024             4     float    none      -1    576.2    0.00    0.00      0    594.5    0.00    0.00      0
        2048             8     float    none      -1    577.1    0.00    0.00      0    601.6    0.00    0.00      0
        4096            16     float    none      -1    576.1    0.01    0.01      0    580.8    0.01    0.01      0
        8192            32     float    none      -1    580.6    0.01    0.01      0    575.5    0.01    0.01      0
       16384            64     float    none      -1    578.0    0.03    0.03      0    607.8    0.03    0.03      0
       32768           128     float    none      -1    578.4    0.06    0.06      0    579.3    0.06    0.06      0
       65536           256     float    none      -1    584.7    0.11    0.11      0    580.2    0.11    0.11      0
      131072           512     float    none      -1    562.8    0.23    0.23      0    590.6    0.22    0.22      0
      262144          1024     float    none      -1    661.0    0.40    0.39      0    623.8    0.42    0.41      0
      524288          2048     float    none      -1    715.0    0.73    0.72      0    777.5    0.67    0.66      0
     1048576          4096     float    none      -1    763.6    1.37    1.35      0    705.9    1.49    1.46      0
     2097152          8192     float    none      -1   1277.2    1.64    1.62      0   1473.5    1.42    1.40      0
     4194304         16384     float    none      -1   1183.1    3.55    3.49      0   1142.4    3.67    3.61      0
     8388608         32768     float    none      -1   1133.5    7.40    7.28      0   1233.5    6.80    6.69      0
    16777216         65536     float    none      -1   1029.6   16.29   16.04      0   1078.2   15.56   15.32      0
    33554432        131072     float    none      -1    986.3   34.02   33.49      0   1031.0   32.55   32.04      0
    67108864        262144     float    none      -1   1587.7   42.27   41.61      0   1588.7   42.24   41.58      0
   134217728        524288     float    none      -1   3150.1   42.61   41.94      0   3142.4   42.71   42.04      0
```