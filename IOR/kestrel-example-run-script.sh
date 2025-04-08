#!/bin/bash

iordir=/projects/esifapps/ohull/ior-hpc4/ior/src

srun -n 2 $iordir/ior -v -a POSIX -g -w -r -e -C -F -b 40G -t 1G -s 1
