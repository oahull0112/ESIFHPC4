## Licensing
LAMMPS is open-source software licensed under the GPLv3. 

Description
-----------
This benchmark was generated using LAMMPS version 22-Jul-2025. The source code for this version is available from [https://github.com/lammps/lammps/releases/tag/stable_22Jul2025](https://github.com/lammps/lammps/releases/tag/stable_22Jul2025). Although we do not specify usage of a particular LAMMPS release, a recent version is preferred. 

This benchmark performs short simulations of a 35% LiCl solution pre-equlibrated to 300 K and 1 atm with about 0.75 million atoms in a cubic cell, ~20 nm on a side. We supply a LAMMPS parameter file `data.begin.bz2`. This compressed file must be uncompressed before any test runs, for example using `bunzip2 data.begin.bz2`. It contains coordinates and velocities of the atoms.

There are 4 benchmark sizes: small, medium, large, and xlarge. The medium, large, and xlarge sizes are generated programatically via the LAMMPS `replicate` input flag in each respective input file. The medium size replicates data.begin into a 2x2x2 supercell, the large a 4x4x4, and the xlarge a 8x8x8. Each benchmark size is locatd in a separate directory with its own `lammps.in` file read by the `lmp` executable. 

For time performance benchmarks, only the medium and large benchmarks are required in the response. The other sizes are only provided for debugging/testing and optional responses. Each size benchmark runs for a specified number of timesteps, printing thermodynamic logging information 10 times along the trajectory. The only value in the input file that can be modified is the thermo_print tag, which may only be increased if a longer trajectory would better showcase the Offeror's system/performance. The total timesteps were selected such that all benchmarks ran in under ~10 minutes on NLR's Kestrel machine using the fewest resources that can hold the system in memory. 

For the correctness validation part of the response, we only require 1 medium benchmark run on both Standard and Accelerated nodes. See the section below for further details and requirements. A directory with reference results and a validation script are provided in the `medium-validation` directory.

Sample Slurm scripts have also been provided for reference in `sample-slurm-scripts`. 

How to Build
------------
Optional libraries or packages included in the LAMMPS distribution (*e.g.*, OpenMP or Intel) may be used for all tests in the reporting spreadsheet.

LAMMPS can be built by following the instructions at [https://lammps.sandia.gov/doc/Install.html](https://docs.lammps.org/Build.html). For systems with GPUs, a version should be built with the LAMMPS GPU or KOKKOS package with the default precision. If the Offeror's chip doesn't support these packages, please contact NLR as soon as possible to discuss possiblilties for using another package.  

How to Run  
----------
The "As-is" benchmark must be run on Standard and Accelerated nodes with no OpenMP parallization, that is, `OMP_NUM_THREADS=1`.

The medium and large benchmarks should be run on N, 2N, 4N, etc... nodes, where N is the smallest number of nodes/devices that can hold the benchmark in memory. The maximum number of nodes in the series should be the maximum number of nodes available to the Offeror for testing. The Offeror may optionally specify `Out of Memory` in the reporting spreadsheet for small node counts if the benchmarks fail due to memory constraints, if that facilitates high-throughput testing. It is possible that the optimal benchmark speed is achieved when the number of MPI ranks per node is smaller than the number of CPU cores per node and in this case, the Offeror may be able improve performance by varying the number of MPI ranks per node to find a more optimal value. The "# cores" reported should reflect the number of physical CPU cores hosting independent threads of execution.

How to Validate
---------------
Numerical results vary somewhat with respect to the number of MPI ranks employed. In recognition of this, we are requesting validation only on two specific runs specifically targeted at validation. The performance results from these validation runs are not to be entered into the reporting sheet. The two runs should both use the `medium-validation/lammps.in`, with 64 MPI ranks, and `OMP_NUM_THREADS=1`, and be run on both Standard and Accelerated nodes. Sample Slurm scripts are provided in `medium-validation` directory. 

A script named `validate.py` is provided to validate system temperature and total energy data from the output of each of these runs against those obtained by NLR. The Offeror should run this script with the first argument as the path to the output file of a validation run, and the second argument the path to the provided directory `NLR_results` containing reference data. The general usage is:

`./validate.py PATH/lammps_output.log NLR-results/medium_validation.log`

(Example: `./validate.py medium_validation/medium_validation.log NLR-results/medium_validation.log`)

This script will print the average temperature and energy for the reference NLR results and Offeror's validation run. These values should be approximately 300 and -8.9e+07, respectively. The next line gives the relative root mean squared error (RMSE) between the NLR reference output provided by NLR (in `medium-validation/NLR-results/medium_validation.log`) and the output from the test run. Reasonable relative deviations are less than 10<sup>-3</sup> for temperature and 10<sup>-5</sup> for energy. The validation script prints either "Run validated successfully" or "Run was NOT validated", depending on whether deviations are less than or greater than these thresholds, respectively.

Reporting Results
-----------------
For the Spreadsheet response, the target performance numbers are "s/timestep" (the inverse of "timesteps/s") as reported in the LAMMPS standard output stream. In addition to these values, the MPItasks, total number of steps that have been run, Loop time (s), and % CPU Usage must be included as well. Example logfile output looks like:

`Loop time of 105.823 on 96 procs for 2500 steps with 744000 atoms`

`Performance: 2.041 ns/day, 11.758 hours/ns, 23.624 timesteps/s, 17.576 Matom-step/s`

`93.8% CPU use with 96 MPI tasks x 1 OpenMP threads`

In this case, the MPI tasks is 96, number-of-steps is 2500, % CPU usage is 93.8, the loop time is 105.823 seconds, the speed is 23.624 timesteps/s, and the performance is 1/23.624 = 0.0423 s/timestep.

We have provided a collection script that facilitates reporting by reading in a list of LAMMPS output file paths and printing a summary table:

`./collect-results.py file1.log file2.log ...`

## What Must be Returned
In addition to the performance benchmark LAMMPS output log files, LAMMPS output log files from the two validation runs should also be included in the File response.

