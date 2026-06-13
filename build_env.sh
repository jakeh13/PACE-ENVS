#!/bin/bash

echo -n "Purging modules... "
module purge
echo "Done"

echo -n "Loading relevant modules... "
# module load gcc
module load gcc
module load swig/4.1.1
module load openblas
module load cmake
module load anaconda3
module load openmpi

conda deactivate

echo -n "creating conda environment with pymeep... "
conda create -n jmh -c conda-forge pymeep=*=mpi_mpich_*