# [DRAFT] ESIF-HPC-4 Benchmark Suite 

Contains benchmarks to be run for NREL's ESIF-HPC-4 procurement.

The purpose of the "draft release" on [DATE] is so that we can make our RFP benchmarking plans transparent to all vendors ahead of the RFP. Our hope is that this early draft release will give vendors additional time to work with our team on the benchmarks, especially as we have a few "in-house" codes represented in the suite that may be unfamiliar to vendors.

This early draft release does not represent or guarantee any final form of the suite.

Please contact olivia.hull@nrel.gov with any questions or comments about the benchmarks, especially if you encounter a specific issue with the building or execution of a benchmark.

Important Notes:
- This is an in-progress draft release.
	- Different benchmarks in the suite are at various states of "in-progress"
	- Most benchmarks do not have finalized inputs or run requirements as of [DATE]
- Benchmarks are divided into "Class A" and "Class B". 
	- "Class A" represents the set of benchmarks for which we care about performance.
	- "Class B" represent the set of benchmarks for which their successful execution on any new machine is critical, but for which we are less interested in performance results or optimization. I.e., these are functionality tests.
- The official version of the benchmark suite will be provided as a release from this repository.
- The official version of the suite will not be available until September 2025 at the earliest.
- Until the official release, we may add or subtract benchmarks, change run requirements, etc.

The below table summarizes each benchmark.
- Class A: we plan to judge the machine based on performance
- Class B: functionality benchmark
- Running a benchmark in an optimized configuration is purely optional

**"Class A" Applications:**
| Application | Standard | Accelerated | Optimized | As-is |
|:-----------:|:--------:|:-----------:|:---------:|:-----:|
| [VASP](https://github.com/NREL/ESIFHPC4/tree/main/VASP)        | Yes      | Yes         | Optional  | Yes   |
| [WRF](https://github.com/NREL/ESIFHPC4/tree/main/WRF)         | Yes      | Yes*        | Optional  | Yes   |
| [MLPerf-3DUnet**](https://github.com/NREL/ESIFHPC4/tree/main/AI-ML/app-level-benchmark)| Yes      | Yes         | Optional  | Yes   |
| [AMR-Wind](https://github.com/NREL/ESIFHPC4/tree/main/AMR-Wind)    | Yes      | Yes         | Optional  | Yes   |
| [LAMMPS](https://github.com/NREL/ESIFHPC4/tree/main/LAMMPS)      | Yes      | Yes         | Optional  | Yes   |

\* WRF acceleration via AceCAST

\** MLPerf-3DUnet can be chosen to run *either* standard or accelerated, though accelerated is preferred.

**"Class B" Applications - functionality only**
| Application | Standard | Accelerated | Optimized | As-is |
|:-----------:|:--------:|:-----------:|:---------:|:-----:|
| [Q-Chem](https://github.com/NREL/ESIFHPC4/tree/main/Q-Chem)      | Yes      | Yes         | No        | Yes   |
| [BerkeleyGW](https://github.com/NREL/ESIFHPC4/tree/main/BerkeleyGW)  | Yes      | Yes         | No        | Yes   |
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
| [HPGMG](https://github.com/NREL/ESIFHPC4/tree/main/HPGMG)       | Yes      | Yes         | Optional  | Yes   |
| FIO***         | Yes      | No          | Optional  | Yes   |

\*** benchmark still in early development; not yet in repo.
