# [DRAFT] ESIF-HPC-4 Benchmark Suite 

Contains benchmarks to be run for NREL's ESIF-HPC-4 procurement.

The purpose of the "draft release" on 5/29/2025 is so that we can make our RFP benchmarking plans transparent to all vendors ahead of the RFP. Our hope is that this early draft release will give vendors additional time to work with our team on the benchmarks, especially as we have a few "in-house" codes represented in the suite that may be unfamiliar to vendors.

This early draft release does not represent or guarantee any final form of the suite.

Important Notes:
- This is an in-progress draft release.
	- Different benchmarks in the suite are at various states of "in-progress"
	- Most benchmarks do not have finalized inputs or run requirements as of 5/29/2025
 - Please see the [Planned Changes](#planned-changes) section of this README for changes that we are planning to make/are in development, but have not yet integrated into this repo.
- Benchmarks are divided into "Class A" and "Class B". 
	- "Class A" - Performance-required benchmarks: set of benchmarks for which specific performance targets must be met or exceeded. 
	- "Class B" - Functionality benchmarks: set of benchmarks intended to demonstrate and baseline the functionality, scalability, and software readiness of specific workloads or system features, but no specific performance level will be required. 
- The official version of the benchmark suite will be provided with the RFP.
- Until the official release, we may add or subtract benchmarks, change run requirements, etc.

**"Class A" Applications:**
| Application | Standard | Accelerated | Optimized | As-is |
|:-----------:|:--------:|:-----------:|:---------:|:-----:|
| [VASP](https://github.com/NREL/ESIFHPC4/tree/main/VASP)        | Yes      | Yes         | Optional  | Yes   |
| [WRF](https://github.com/NREL/ESIFHPC4/tree/main/WRF)         | Yes      | Yes*        | Optional  | Yes   |
| [MLPerf-3DUnet**](https://github.com/NREL/ESIFHPC4/tree/main/AI-ML/app-level-benchmark)| Yes      | Yes         | Optional  | Yes   |
| [AMR-Wind](https://github.com/NREL/ESIFHPC4/tree/main/AMR-Wind)    | Yes      | Yes         | Optional  | Yes   |
| [LAMMPS](https://github.com/NREL/ESIFHPC4/tree/main/LAMMPS)      | Yes      | Yes         | Optional  | Yes   |
| [BerkeleyGW](https://github.com/NREL/ESIFHPC4/tree/main/BerkeleyGW)  | Yes      | Yes         | Optional        | Yes   |

\* WRF acceleration via AceCAST

\** MLPerf-3DUnet can be chosen to run *either* standard or accelerated, though accelerated is preferred.

**"Class B" Applications - functionality only**
| Application | Standard | Accelerated | Optimized | As-is |
|:-----------:|:--------:|:-----------:|:---------:|:-----:|
| [Sienna](https://github.com/NREL/ESIFHPC4/tree/main/Sienna-Ops)      | Yes      | No          | No        | Yes   |

**Microbenchmarks:**
| Application | Standard | Accelerated | Optimized | As-is |
|:-----------:|:--------:|:-----------:|:---------:|:-----:|
| [OSU](https://github.com/NREL/ESIFHPC4/tree/main/OSU)         | Yes      | No          | Optional  | Yes   |
| [HPL](https://github.com/NREL/ESIFHPC4/tree/main/HPL)         | Yes      | Yes         | Optional  | Yes   |
| [Stream](https://github.com/NREL/ESIFHPC4/tree/main/stream)      | Yes      | Yes         | Optional  | Yes   |
| [IOR](https://github.com/NREL/ESIFHPC4/tree/main/IOR)         | Yes      | No          | Optional  | Yes   |
| [mdtest](https://github.com/NREL/ESIFHPC4/tree/main/mdtest)      | Yes      | No          | Optional  | Yes   |
| [GPU-GPU collective](https://github.com/NREL/ESIFHPC4/tree/main/AI-ML/microbenchmark)| No | Yes         | Optional  | Yes   |
| FIO***         | Yes      | No          | Optional  | Yes   |

\*** benchmark still in early development; not yet in repo.

## Planned Changes
We have planned/upcoming changes to the suite that have not yet been integrated but are currently in development. We list any major not-yet-integrated changes here. Please note that this list is subject to change, and we make no guarantee that these changes are reflected in the finalized benchmark suite.

- AI/ML: We plan to change the AI application-level benchmark from MLPerf's 3DUnet to MLPerf's DeepCAM benchmark.
- WRF: We plan to remove the AceCAST/GPU portion of WRF, along with any requests for simultaneous/concurrent runs on test hardware.
- VASP: Bench 1 will now focus only on the HSE calculation, with the supercell increased from 16 atoms to 128 atoms. Bench 2 will be a vasp_gam single-kpoint GGA calculation with 1149 atoms, increased from 519 atoms.
- LAMMPS: We are developing an "extra large" size input that should better utilize future hardware.
- AMR-Wind: We plan to remove any requests for simultaneous/concurrent runs on test hardware.

## Changelog

### September 22, 2025
- Removed HPGMG from the suite

### July 29, 2025
- Removed Q-Chem from the suite
- Moved BerkeleyGW from "Class B" to "Class A"
