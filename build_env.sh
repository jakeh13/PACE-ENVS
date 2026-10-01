#!/bin/bash
# Usage:  bash PACE-ENVS/build_env.sh
#
# Builds the `jmh` conda env used by BEEF and the TO engines (to-tools-beef; the
# older to-tools-Jacob needs the same packages). If `jmh` already exists, run
# destroy_env.sh first -- this script refuses to overwrite it.
#
# What goes where, and why:
#   conda-forge   pymeep (MPICH build), nlopt, scikit-image
#                 meep must come from conda-forge; PyPI's "meep" is an unrelated
#                 package. nlopt/scikit-image come from conda so they match the
#                 numpy that pymeep pins.
#   pip           meow-sim from git main (NOT the PyPI release), then the rest.
#   pip -e        BEEF (and to-tools-beef once it has a pyproject.toml), editable
#                 so the checkouts stay the source of truth.

HERE="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
ENV_NAME=jmh
BEEF_DIR="$(readlink -f "$HERE/../BEEF")"
TTB_DIR="$(readlink -f "$HERE/../to-tools-beef")"
MEOW_REF="${MEOW_REF:-b6ba461bccf4d0e4e3dc18e98c728fa16da50e65}"

# The pymeep solve needs more than the 4 GiB a PACE login-node session is capped
# at; the OOM killer silently kills conda ("Solving environment: ... Killed").
# Run it as a job:  sbatch PACE-ENVS/build_env.sbatch   (or inside salloc/srun).
if [ -z "$SLURM_JOB_ID" ] && [ -z "$FORCE_LOGIN_BUILD" ]; then
    echo "Not inside a SLURM job. Submit it instead:  sbatch PACE-ENVS/build_env.sbatch" >&2
    echo "(set FORCE_LOGIN_BUILD=1 to try on a login node anyway)" >&2
    exit 1
fi

source "$HERE/modules.sh"

if conda env list | awk '{print $1}' | grep -qx "$ENV_NAME"; then
    echo "Conda env '$ENV_NAME' already exists. Run PACE-ENVS/destroy_env.sh first." >&2
    exit 1
fi

echo "Creating conda environment with pymeep... "
# --override-channels: skip the (large, and binary-incompatible) `defaults`
# channels that the PACE anaconda3 module configures; pymeep is conda-forge only.
conda create -y -n "$ENV_NAME" --override-channels -c conda-forge \
    "python>=3.11" \
    "pymeep=*=mpi_mpich_*" \
    nlopt \
    scikit-image \
    || { echo "conda create failed" >&2; exit 1; }

conda activate "$ENV_NAME" || { echo "could not activate $ENV_NAME" >&2; exit 1; }

echo "Installing meow from git (ref ${MEOW_REF})... "
# The MEEP FDE backend that mode_solver="meep" needs was merged upstream as
# 0cde1ae ("feat: add MEEP FDE backend", #62) AFTER the latest release, so
# `pip install meow-sim` installs 0.15.0, which has no meow/fde/meep.py and fails
# on `from meow import compute_modes_meep`. Seven files in BEEF ask for
# mode_solver="meep", including beef/solvers/hybrid.py.
# Pinned to a commit (main as of 2026-10-01, verified with BEEF) so rebuilds are
# reproducible. To try newer meow: MEOW_REF=main sbatch PACE-ENVS/build_env.sbatch
pip install "meow-sim @ git+https://github.com/gdsfactory/meow.git@${MEOW_REF}" \
    || { echo "meow install failed" >&2; exit 1; }

echo "Installing various python packages... "
#   gdsfactory, gdspy      layout/GDS handling (meow, to-tools GDS export)
#   dataconf               JSON config loading (to-tools hyperparams)
#   opencv-python          contour detection for area constraints / seeded TO
#   imageruler             linewidth/spacing violation maps (DRC, seeded TO)
#   autograd               backprop through the filter/projection pipeline
pip install gdsfactory dataconf opencv-python gdspy imageruler autograd \
    || { echo "pip install failed" >&2; exit 1; }

echo "Installing BEEF itself (editable)... "
# Without this nothing imports: every example and test opens with
# `from beef import ...`. Editable on purpose -- SLURM jobs import beef/ from the
# working tree at start time. [dev,gds] adds pytest and gdstk.
pip install -e "$BEEF_DIR[dev,gds]" \
    || { echo "BEEF install failed" >&2; exit 1; }

if [ -f "$TTB_DIR/pyproject.toml" ]; then
    echo "Installing to-tools-beef itself (editable)... "
    pip install -e "$TTB_DIR" || { echo "to-tools-beef install failed" >&2; exit 1; }
else
    echo "Skipping to-tools-beef: no $TTB_DIR/pyproject.toml yet."
fi

echo "Verifying environment... "
python "$HERE/verify_env.py" "$BEEF_DIR"
