## Licensing
LAMMPS is open-source software licensed under the GPLv3. 

Description
-----------
This benchmark was generated using LAMMPS version 22-Jul-2025. The source code for this version is available from [https://github.com/lammps/lammps/releases/tag/stable_22Jul2025](https://github.com/lammps/lammps/releases/tag/stable_22Jul2025). Although we do not specify usage of a particular LAMMPS release, a recent version is preferred. 

This benchmark performs short simulations of a 35% LiCl solution pre-equlibrated to 300 K and 1 atm with about 0.75 million atoms in a cubic cell, ~20 nm on a side. We supply a LAMMPS parameter file `data.begin.bz2`. This compressed file must be uncompressed before any test runs, for example using `bunzip2 data.begin.bz2`. It contains coordinates and velocities of the atoms.

There are 4 benchmark sizes: small, medium, large, and xlarge. The medium, large, and xlarge sizes are generated programatically via the LAMMPS `replicate` input flag in each respective input file, while the small benchmark uses the structure 'as-is' in the `data.begin` file. The medium size replicates data.begin into a 2x2x2 supercell, the large a 4x4x4, and the xlarge a 8x8x8. Each benchmark size is locatd in a separate directory with its own `lammps.in` file read by the `lmp` executable. 

For time performance benchmarks, only the medium and xlarge benchmarks are required in the response. The other sizes are only provided for debugging/testing and optional responses. Each size benchmark runs for a specified number of timesteps, printing thermodynamic logging information 10 times along the trajectory. The only value in the input file that can be modified is the thermo_print tag, which may only be increased if a longer trajectory would better showcase the Offeror's system/performance. The total timesteps were selected such that all benchmarks ran in under ~10 minutes on NLR's Kestrel machine using the fewest resources that can hold the system in memory. 

For the correctness validation part of the response, we only require 2 short medium benchmark runs, 1 for a Standard node and 1 for an Accelerated node. See the section below for further details and requirements. A directory with reference results and a validation script are provided in the `medium-validation` directory.

Sample Slurm scripts have also been provided for reference in `sample-slurm-scripts`. 

How to Build
------------
Optional libraries or packages included in the LAMMPS distribution (*e.g.*, OpenMP or Intel) may be used for all tests in the reporting spreadsheet.

LAMMPS can be built by following the instructions at [https://lammps.sandia.gov/doc/Install.html](https://docs.lammps.org/Build.html). For systems with GPUs, a version should be built with the LAMMPS GPU or KOKKOS package with the default precision. If the Offeror's chip doesn't support these packages, please contact NLR as soon as possible to discuss possiblilties for using another package. All benchmarks should be run using FP64. 

How to Run  
----------
The "As-is" benchmark must be run on Standard and Accelerated nodes with no OpenMP parallization, that is, `OMP_NUM_THREADS=1`.

The medium and large benchmarks should be run on N, 2N, 4N, etc... nodes, where N is the smallest number of nodes/devices that can hold the benchmark in memory. The maximum number of nodes in the series should be the maximum number of nodes available to the Offeror for testing. The Offeror may optionally specify `Out of Memory` in the reporting spreadsheet for small node counts if the benchmarks fail due to memory constraints. It is possible that the optimal benchmark speed is achieved when the number of MPI ranks per node is smaller than the number of CPU cores per node and in this case, the Offeror may be able improve performance by varying the number of MPI ranks per node to find a more optimal value. The "# cores" reported should reflect the number of physical CPU cores hosting independent threads of execution.

How to Validate
---------------
Molecular dynamics simulations involve solving coupled partial differential equations and are thus Lyapunov unstable. As such, exact numerical reproducibility is challenging and not practical. Differences among systems can be redcued however by running using the same number of processors. In recognition of this, we are requesting validation only on two specific runs specifically targeted at validation. The performance results from these validation runs are not to be entered into the reporting sheet. The two runs should both use the `medium-validation/lammps.in`, with 64 MPI ranks, and `OMP_NUM_THREADS=1`. One should be run on a Standard node and one should be run on an Accelerated node. Sample Slurm scripts are provided in `medium-validation` directory. 

A script named `validate.py` is provided to validate system temperature and total energy data from the output of each of these runs against those obtained by NLR. The Offeror should run this script with the first argument as the path to the output file of a validation run, and the second argument the path to the provided directory `NLR_results` containing reference data. The general usage when running the script from the `medium-validation` directory is:

`./validate.py your_lammps_output_file_name.out NLR-results/lammps.out`

This script will print the temperature and energy for the reference NLR results and Offeror's validation run after 100 timesteps. These values should be approximately 300 and -8.9e+07, respectively. The next line gives the relative error between the NLR reference output provided by NLR in `medium-validation/NLR-results/lammps.out`) and the output from the test run. Reasonable relative deviations are less than 10<sup>-4</sup> for temperature and 10<sup>-5</sup> for energy. The validation script prints either "Run validated successfully" or "Run was NOT validated", depending on whether deviations are less than or greater than these thresholds, respectively.

Reporting Results
-----------------
For the Spreadsheet response, the target performance numbers are "s/timestep" (the inverse of "timesteps/s") as reported in the LAMMPS standard output stream. In addition to these values, the MPItasks, total number of steps that have been run, Loop time (s), and % CPU Usage must be included as well. Example logfile output looks like:

`Loop time of 105.823 on 96 procs for 2500 steps with 744000 atoms`

`Performance: 2.041 ns/day, 11.758 hours/ns, 23.624 timesteps/s, 17.576 Matom-step/s`

`93.8% CPU use with 96 MPI tasks x 1 OpenMP threads`

In this case, the MPI tasks is 96, number-of-steps is 2500, % CPU usage is 93.8, the loop time is 105.823 seconds, the speed is 23.624 timesteps/s, and the performance is 1/23.624 = 0.0423 s/timestep.

For convenience, we have provided a collection script that facilitates reporting by reading in a list of LAMMPS output file paths and printing a summary table:

`./collect-perf-results.py file1.out file2.out ...`

All NLR results can be collected via the helper script `summarize_nlr_results.sh`.

A summary of NLR's standard node results is shown below. These results were generated using dual socket Intel Xeon Sapphire Rapids CPU nodes with 96 MPI tasks per node and `OMP_NUM_THREADS=1`.

| Benchmark | MPItasks | Nsteps | LoopTime(s) | %CPUusage | Performance(timesteps/s) | Performance(s/timestep) |
|:---------:|:--------:|:------:|:-----------:|:---------:|:------------------------:|:-----------------------:|
|   Small   |    96    |  2500  |   105.823   |    93.8   |          23.624          |          0.0423         |
|   Small   |    192   |  2500  |    59.086   |    95.3   |          42.311          |          0.0236         |
|   Small   |    384   |  2500  |    81.790   |    98.2   |          30.566          |          0.0327         |
|   Medium  |    96    |  1500  |   512.447   |    96.0   |           2.927          |          0.3416         |
|   Medium  |    192   |  1500  |   266.000   |    97.4   |           5.639          |          0.1773         |
|   Medium  |    384   |  1500  |   137.532   |    97.8   |          10.907          |          0.0917         |
|   Large   |    96    |   200  |   561.041   |    97.7   |           0.356          |          2.8090         |
|   Large   |    192   |   200  |   278.001   |    98.2   |           0.719          |          1.3908         |
|   Large   |    384   |   200  |   135.569   |    98.3   |           1.475          |          0.6780         |
|   Xlarge  |    384   |   100  |   578.232   |    98.6   |           0.173          |          5.7803         |
|   Xlarge  |    768   |   100  |   307.673   |    98.8   |           0.325          |          3.0769         |

A summary of NLR's accelerated node results is shown below. These results were generated using dual socket nodes with AMD Genoa CPU and four NVIDIA H100 SXM GPUs with 80 GB memory using 32 MPI tasks per node and all GPUs on each node and `OMP_NUM_THREADS=1`. Therefore, the number of GPUs used for each calculation can be found by dividing the MPItasks column by 32 and multiplying by 4. 

| Benchmark | MPItasks | Nsteps | LoopTime(s) | %CPUusage | Performance(timesteps/s) | Performance(s/timestep) |
|:---------:|:--------:|:------:|:-----------:|:---------:|:------------------------:|:-----------------------:|
|   Small   |    32    |  2500  |    41.609   |    90.1   |          60.084          |          0.0166         |
|   Small   |    64    |  2500  |    27.442   |    92.5   |          91.101          |          0.0110         |
|   Medium  |    32    |  1500  |   123.490   |    86.4   |          12.147          |          0.0823         |
|   Medium  |    64    |  1500  |    68.617   |    89.5   |          21.861          |          0.0457         |
|   Large   |    32    |   200  |   141.742   |    93.8   |           1.411          |          0.7087         |
|   Large   |    64    |   200  |    67.952   |    93.9   |           2.943          |          0.3398         |
|   Large   |    128   |   200  |    37.309   |    94.9   |           5.361          |          0.1865         |

## What Must be Returned
In addition to the performance benchmark LAMMPS output log files, LAMMPS output log files from the two validation runs should also be included in the File Response.

