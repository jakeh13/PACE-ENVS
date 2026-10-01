#!/bin/bash
# Usage:  bash PACE-ENVS/destroy_env.sh
# Removes the `jmh` conda env (needed before build_env.sh can rebuild it).

source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/modules.sh"

conda env remove -y -n jmh
