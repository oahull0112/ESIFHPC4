# WRF
## Purpose and Description

The Weather Research and Forecasting model (WRF) from [NCAR](https://www.mmm.ucar.edu/weather-research-and-forecasting-model) is a mesoscale numerical system used in atmospheric research and operational forecasting. [AceCAST] (https://tempoquest.com/acecast/), a commercially available version of WRF, runs on high-performance GPUs. This benchmark assesses system throughput under stress, and how communication affects applications' performance.

## Licensing Requirements

The WRF Model is open-source code in the public domain, and its use is unrestricted. The WRF public domain notice and related information may be found [here](https://www2.mmm.ucar.edu/wrf/users/public.html).

## How to build

Build instructions for any `WRF` and `WPS` can be found [here](https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compilation_tutorial.php). Additionally, build instruction for AceCAST can be found [here](https://acecast-docs.readthedocs.io/en/latest/InstallationGuide.html#). For building [WRFv4.6.1 and WPSv4.6.0](https://nrel.github.io/HPC/Documentation/Applications/wrf/) on Kestrel, the following programming environment and library modules were loaded.

```
1) PrgEnv-gnu/8.5.0    2) cray-mpich/8.1.28  3) cray-libsci/23.12.5
4) zlib/1.3.1	       5) hdf5/1.14.6	     6)  pnetcdf/1.14.0
7) netcdf-c/4.9.3      8) netcdf-fortran/4.6.1
9) libpng/1.6.47       10) jasper/1.900.1

```

## Run Definitions and Requirements

A reference WRF output file will be provided for validating your run outputs using the `Diffwrf` program.`Diffwrf` will compare your output with the reference output file and generate difference statistics for each field that is not bit-for-bit identical to the reference output. The following command can be issued to obtain differences between the outputs (diffout_tag), where tag is name of a run.

A reference file to validate your WRF run outputs using `Diffwrf` will be provided. `Diffwrf` contrasts your output with the reference, generating statistics for fields differing from the reference output. The following command can be issued to obtain output differences (diffout_tag), with 'tag' being the run identifier.

```
$ python diffwrf.py wrfout_d01_2019-11-27_00:00:00 wrfout_reference > diffout_tag

```

## How to run
The [Conus2.5km WRFV4.4 benchmark](https://www2.mmm.ucar.edu/wrf/users/benchmark/v44/v4.4_bench_conus2.5km.tar.gz) will be used for measuring performance and scaling of target architectures.

* To run WRF on CPUs, copy wrfinput_d01, wrfbdy_d01, namelist.input, and *.dat from the benchmark directory and copy runtime files from WRF/run/<files> in the run directory. The benchmark results can be obtained using `srun` as following:
  
  ```
  $ srun -N <total number of nodes> -n <total number of MPI ranks per node> --ntasks-per-node=<number of MPI ranks per node> ./wrf.exe

  ```

* To run AceCAST on GPUs, copy runtime files from `acecast-v4.0.2/acecast/run/*`, and copy wrfinput_d01, wrfbdy_d01, namelist.input, and *.dat files from benchmark directory in the run directory. The benchmark results can be obtained using `mpirun` as following:

  ```
  $ mpirun -n <total number of MPI ranks> -N < Number of MPI ranks per node> --hostfile hostfile ./gpu-launch.sh ./acecast.exe

  ```

### Tests

Strong scaling and throughput tests will be performed using the CONUS benchmarks on single and multiple CPU and GPU nodes. CONUS-12km will be used on the single-node while CONUS-2.5km will be used on multi-node runs. The Offeror should run 4-6 concurent jobs instances of the benchmark on the target system. The harmonic-mean of the runtime from the cuncurrent jobs will be used for reporting strong-scaling results. The application throughput can be computed as following: `throughput = allocation factor * node-class count) / (number of nodes * runtime)`

## Run Rules

* The Offeror can use any WRFv4.6.x and WPSv4.6.x version, with later gnu or intel compilers and libraries, and change the provided configure scripts as needed.
* The Offeror must detail any optimizations used in building and running these benchmarks.

## Benchmark test results to report and files to return

* For scaling and throughput reporting, the harmonic mean of the wallclock time (`Timing for main`) reported in `rsl.out.0000` files should be entered into the Spreadsheet response.
* The Text response should include high-level descriptions of build and run optimizations.
* The file response should include namelist.input, configure.wrf, rsl.error.0000 and rsl.out.0000, and diffout_tag files
