#!/bin/bash
# Usage (from the beef_TO repo root):  sbatch PACE-ENVS/build_env.sbatch
# Builds the `jmh` env on a compute node. Needed because the conda solve for
# pymeep exceeds the 4 GiB memory cap on login nodes. If `jmh` already exists,
# run `bash PACE-ENVS/destroy_env.sh` first.
#
# Log: build_env_<jobid>.out in the directory you submitted from.

#SBATCH -J build_jmh_env
#SBATCH --account=gts-sr108-gedc_main
#SBATCH -q inferno
#SBATCH -N 1 -n 1 -c 4
#SBATCH --mem=24G
#SBATCH -t 60
#SBATCH -o build_env_%j.out
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=jhiesener3@gatech.edu

# sbatch runs a copy of this file from a spool directory, so locate the repo via
# the submit directory rather than via $0 / BASH_SOURCE.
cd "$SLURM_SUBMIT_DIR" || exit 1
if [ ! -f PACE-ENVS/build_env.sh ]; then
    echo "Submit from the beef_TO repo root (PACE-ENVS/build_env.sh not found in $PWD)" >&2
    exit 1
fi

bash PACE-ENVS/build_env.sh
