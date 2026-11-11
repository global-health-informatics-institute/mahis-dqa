"""Run the DQA for every program, then build the share-safe workbooks.

    python3 run_all.py                 # all programs, then shared/*.xlsx
    python3 run_all.py --only anc pnc  # selected programs
    python3 run_all.py --skip-shareable
"""
import argparse
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.abspath(__file__))
PROGRAMS = {
    "neonatal": "neonatal/dqa/run_neonatal_dqa.py",
    "anc": "anc/dqa/run_anc_dqa.py",
    "ld": "ld/dqa/run_ld_dqa.py",
    "pnc": "pnc/dqa/run_pnc_dqa.py",
}

ap = argparse.ArgumentParser()
ap.add_argument("--only", nargs="+", choices=sorted(PROGRAMS), help="run only these programs")
ap.add_argument("--skip-shareable", action="store_true", help="do not build the share-safe workbooks")
args = ap.parse_args()

for name in (args.only or PROGRAMS):
    print(f"\n=== {name} ===", flush=True)
    r = subprocess.run([sys.executable, os.path.join(ROOT, PROGRAMS[name])], cwd=ROOT)
    if r.returncode:
        sys.exit(f"{name} failed (exit code {r.returncode}). See the message above.")
if not args.skip_shareable:
    print("\n=== share-safe workbooks ===", flush=True)
    sys.exit(subprocess.run([sys.executable, os.path.join(ROOT, "make_shareable.py")], cwd=ROOT).returncode)
