"""MPI smoke test for the `jmh` env. Launched by test_mpi.sbatch under each launcher.

Passes only if every launched process sees the same world of size N (not N
separate size-1 worlds, which is what a launcher/PMI mismatch silently gives you),
a collective works across nodes, and meep splits one simulation over all ranks.
"""
import socket
import sys

from mpi4py import MPI

comm = MPI.COMM_WORLD
rank, size = comm.Get_rank(), comm.Get_size()
expected = int(sys.argv[1]) if len(sys.argv) > 1 else None
host = socket.gethostname().split(".")[0]

hosts = comm.allgather(host)
total = comm.allreduce(rank, op=MPI.SUM)

import meep as mp  # noqa: E402 - after MPI init on purpose, as in real runs

mp.verbosity(0)
sim = mp.Simulation(
    cell_size=mp.Vector3(8, 4),
    resolution=20,
    boundary_layers=[mp.PML(1.0)],
    geometry=[mp.Block(size=mp.Vector3(mp.inf, 0.5), material=mp.Medium(index=3.48))],
    sources=[mp.Source(mp.GaussianSource(1 / 1.55, fwidth=0.1),
                       component=mp.Ez, center=mp.Vector3(-2.5))],
)
sim.run(until=20)
ez = sim.get_field_point(mp.Ez, mp.Vector3(2.5))  # collective: same value on all ranks
ez_all = comm.allgather(complex(ez))

ok = (
    (expected is None or size == expected)
    and total == size * (size - 1) // 2
    and mp.count_processors() == size
    and all(abs(z - ez_all[0]) < 1e-12 for z in ez_all)
)

if rank == 0:
    nodes = sorted(set(hosts))
    print(f"size={size} expected={expected} nodes={len(nodes)} {nodes} "
          f"meep_procs={mp.count_processors()} Ez={ez_all[0]:.4e}")
    print("RESULT:", "PASS" if ok else "FAIL")
sys.stdout.flush()
# A launcher that starts N independent size-1 worlds makes every process rank 0,
# so it prints N RESULT lines with size=1 -- test_mpi.sbatch counts them.
sys.exit(0 if ok else 1)
