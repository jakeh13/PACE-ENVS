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

echo -n "Installing various python packages... "
# meow from GitHub main, NOT the PyPI release. The MEEP FDE backend that
# mode_solver="meep" needs was merged upstream as 0cde1ae ("feat: add MEEP
# FDE backend", #62) AFTER the latest release, so `pip install meow-sim`
# installs 0.15.0, which has no meow/fde/meep.py and fails on
# `from meow import compute_modes_meep`. Seven files in BEEF ask for
# mode_solver="meep", including beef/solvers/hybrid.py.
pip install "meow-sim @ git+https://github.com/gdsfactory/meow.git@main"
pip install gdsfactory
pip install dataconf
pip install opencv-python
pip install gdspy

echo -n "Installing BEEF itself (editable)... "
# Without this nothing imports: every example and test opens with
# `from beef import ...`. Editable on purpose -- the checkout stays the
# source of truth, and SLURM jobs import beef/ from the working tree at
# start time.
pip install -e "$(dirname "$(readlink -f "$0")")/../BEEF"
