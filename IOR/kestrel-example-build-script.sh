#!/bin/bash

module load cray-hdf5-parallel

git clone git@github.com:hpc/ior.git --branch 4.0 
cd ior 
./bootstrap
./configure CC=cc MPICC=cc --with-hdf5
make

# As per https://github.com/hpc/ior/blob/main/README_HDF5, 
# For HDF5, you may need to include in the configure line:
# ./configure [other options] --with-hdf5 CFLAGS="-I /path/to/installed/hdf5/include" LDFLAGS="-L /path/to/installed/hdf5/lib"

# Environment:
#Currently Loaded Modules:
#  1) craype-x86-spr    3) craype/2.7.30      5) libfabric/1.15.2.0   7) cray-mpich/8.1.28     9) PrgEnv-gnu/8.5.0  11) cray-hdf5-parallel/1.12.2.9
#  2) gcc-native/12.1   4) cray-dsmml/0.2.2   6) craype-network-ofi   8) cray-libsci/23.12.5  10) git/2.45.1
