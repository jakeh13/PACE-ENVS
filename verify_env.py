"""Smoke-test the `jmh` env. Run inside the activated env:

    python PACE-ENVS/verify_env.py [expected_beef_checkout]

Exits non-zero if anything is missing or stale. It checks the specific things
that went wrong in earlier builds: meow from PyPI instead of git main, BEEF
installed editable from the wrong checkout, nlopt/imageruler missing, and a
non-MPICH MPI under meep/mpi4py.
"""
import importlib
import os
import sys

problems = []


def check(label, fn):
    try:
        detail = fn()
        print(f"  ok    {label}" + (f"  [{detail}]" if detail else ""))
    except Exception as e:  # noqa: BLE001 - report everything, keep going
        print(f"  FAIL  {label}: {type(e).__name__}: {e}")
        problems.append(label)


def mod(name):
    def f():
        m = importlib.import_module(name)
        return getattr(m, "__version__", "")
    return f


print(f"python {sys.version.split()[0]}  ({sys.executable})")
if sys.version_info < (3, 11):
    problems.append("python>=3.11")
    print("  FAIL  BEEF requires python>=3.11")

for name in ["numpy", "scipy", "matplotlib", "skimage", "cv2", "h5py", "gdstk",
             "gdspy", "dataconf", "autograd", "jax", "sax", "nlopt",
             "imageruler", "meep", "meep.adjoint", "mpi4py", "meow"]:
    check(f"import {name}", mod(name))


def meow_has_meep_fde():
    # The MEEP FDE backend (mode_solver="meep") only exists on meow's git main,
    # not in the 0.15.0 PyPI release.
    from meow import compute_modes_meep  # noqa: F401
    return "compute_modes_meep present"


def mpi_is_mpich():
    import meep as mp
    from mpi4py import MPI
    lib = MPI.Get_library_version()
    if "MPICH" not in lib:
        raise RuntimeError(f"mpi4py is not linked against MPICH: {lib[:60]!r}")
    if not mp.with_mpi():
        raise RuntimeError("meep was built without MPI")
    return lib.splitlines()[0][:40]


def beef_location():
    import beef
    here = os.path.dirname(os.path.dirname(os.path.abspath(beef.__file__)))
    if len(sys.argv) > 1:
        want = os.path.realpath(sys.argv[1])
        if os.path.realpath(here) != want:
            raise RuntimeError(f"beef imported from {here}, expected {want}")
    return here


def meep_adjoint_ok():
    import meep.adjoint as mpa
    return mpa.OptimizationProblem.__name__


check("meow git-main features", meow_has_meep_fde)
check("MPI is conda MPICH", mpi_is_mpich)
check("meep.adjoint.OptimizationProblem", meep_adjoint_ok)
check("beef import location", beef_location)

# Optional: to-tools-beef is only installed once its pyproject.toml exists.
try:
    importlib.import_module("to_tools_beef")
    print("  ok    import to_tools_beef")
except ModuleNotFoundError:
    print("  skip  to_tools_beef not installed (no pyproject.toml yet)")

print()
if problems:
    print(f"{len(problems)} problem(s): {', '.join(problems)}")
    sys.exit(1)
print("environment OK")
