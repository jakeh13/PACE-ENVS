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

echo -n "Creating conda environment with pymeep... "
conda create -n jmh -c conda-forge pymeep=*=mpi_mpich_*

conda activate jmh

echo -n "Cloning meow_MEEP repo... "
cd ..
rmdir /s "repos_PACE-ENVS" 2>nul
mkdir -p repos_PACE-ENVS
cd repos_PACE-ENVS
git clone https://github.com/jakeh13/meow_MEEP.git
cd meow_MEEP
pip install -e .
cd ../../PACE-ENVS

echo -n "Installing various python packages... "
pip install gdsfactory
pip install dataconf
pip install opencv-python
pip install gdspy