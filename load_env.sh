#!/bin/bash
# Usage:  source PACE-ENVS/load_env.sh     (must be sourced, not executed)
# Loads the PACE modules and activates the `jmh` conda env.

source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/modules.sh"

conda activate jmh
