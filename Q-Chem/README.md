# Q-Chem and BrianQC

## Purpose and Description

[Q-Chem](https://www.q-chem.com/) is an ab initio quantum chemistry software package for modeling of molecular systems and [BrianQC](https://www.brianqc.com/) is its GPU version. This benchmark performs DFT geometry optimization calculations for a Nafion monomer with different basis sets. The small job uses 6-31G*, and medium job uses 6-311++G(2d,2p), and the large job uses aug-cc-pvtz.

## Licensing Requirements

Both Q-Chem and BrianQC are commercial packages and vendors should follow the instructions on their websites to obtain licenses and install these packages. If Q-Chem and/or BrianQC doesn't support the chip that you propose to use, please contact NREL as soon as possible.

## Run Definitions and Requirements

The file "input.com" defines the initial geometry and calculation method. The "qchem" and "brianqc" directories contain the Slurm script and submitting script. In order to run a Q-Chem test using one computational node (let's call it "q1"):
```
cp -r qchem q1
cd q1
./submit_job.sh
```
The submit_job.sh will automatically create three sub-directories, namely "large", "medium", and "small", and then submit one job for each through Slurm. If you want to change job names, please edit the 2nd line of submit_job.sh. If you want to use more than one node or change the number of tasks per node (or number of GPUs per node for BrianQC jobs), please change the header part of job.slurm file.

When the three jobs have completed, you can use
```
../get_result.sh > output
```
in the "q1" directory to get the final energy (in order to ensure calculation converges correctly) and wall time. The output of "get_result.sh" (namely, "output") should be return to NREL.

In order to run a BrianQC test using one computing node and one GPU per node (let's call it "b11"):
```
cp -r brianqc b11
cd b11
./submit_job.sh
#After all three jobs have completed
../get_result.sh > output
```
We supply "q1_nrel" and "b11_nrel" directories as the sample results obtained from NREL's computer. 

## Benchmark test results to report and files to return

Vendors are expected to run Q-Chem tests on one and/or more computing nodes and BrianQC tests on one and/or more computing nodes with one and/or more GPUs until the wall time doesn't decrease, although we don't expect Q-Chem will have a good scaling for multi-node jobs (especially for smaller jobs). The output for each test should be returned to NREL. 

