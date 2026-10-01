#!/bin/bash
# Shared by build_env.sh, load_env.sh and destroy_env.sh (source it, don't run it).
#
# openmpi is deliberately NOT loaded: the `jmh` env gets its MPI from conda
# (pymeep=*=mpi_mpich_* pulls conda-forge mpich, and mpi4py/h5py/fftw are built
# against it). Loading the openmpi module as well put a second, unrelated MPI on
# PATH/LD_LIBRARY_PATH for no benefit. mpirun/mpiexec come from the env itself.

echo -n "Purging modules... "
module purge
echo "Done"

echo -n "Loading relevant modules... "
module load gcc
module load swig/4.1.1
module load openblas
module load cmake
module load anaconda3
echo "Done"

# Make `conda activate` work whether the caller sourced us or ran us as a script.
eval "$(conda shell.bash hook)"
conda deactivate
