#!/bin/bash
# Usage (from the beef_TO repo root):  sbatch PACE-ENVS/test_mpi.sbatch
# Checks which MPI launchers actually work with the `jmh` env's conda MPICH,
# across 2 nodes. Log: test_mpi_<jobid>.out in the submit directory.

#SBATCH -J test_jmh_mpi
#SBATCH --account=gts-sr108-gedc_main
#SBATCH -q inferno
#SBATCH -N 2 --ntasks-per-node=2
#SBATCH --mem-per-cpu=2G
#SBATCH -t 15
#SBATCH -o test_mpi_%j.out

cd "$SLURM_SUBMIT_DIR" || exit 1
source PACE-ENVS/load_env.sh

N=$SLURM_NTASKS
echo "jmh env: $(which python)"
echo "mpirun:  $(which mpirun)"
echo "nodes:   $SLURM_JOB_NODELIST  ntasks=$N"
echo

summary=""
run() {
    local label="$1"; shift
    echo "=== $label: $*"
    out="$("$@" python PACE-ENVS/test_mpi.py "$N" 2>&1)"
    echo "$out" | grep -E "size=|RESULT|rror" | head -8
    n_pass=$(echo "$out" | grep -c "RESULT: PASS")
    n_res=$(echo "$out" | grep -c "RESULT:")
    if [ "$n_pass" -eq 1 ] && [ "$n_res" -eq 1 ]; then v=PASS
    elif [ "$n_res" -gt 1 ]; then v="FAIL ($n_res independent size-1 worlds)"
    else v=FAIL; fi
    echo "--> $v"; echo
    summary+=$(printf '%-28s %s' "$label" "$v")$'\n'
}

run "srun --mpi=pmi2"   srun --mpi=pmi2 -n "$N"
run "srun --mpi=pmix"   srun --mpi=pmix -n "$N"
run "srun (default)"    srun -n "$N"
run "mpirun (env hydra)" mpirun -np "$N"

echo "===== SUMMARY ====="
printf '%s' "$summary"
