#!/usr/bin/env python3
"""
Usage:
  ./validate.py PATH/lammps_output.log NLR-results/medium_validation.log

Parses the first thermo block (from the header line containing 'Step' up to the
line containing 'Loop') and compares Temp and TotEng between the two logs.
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
import pandas as pd


def read_thermo_block(path: str | Path) -> pd.DataFrame:
    """Extract Step, Temp, TotEng from a LAMMPS-style log thermo block."""
    rows: list[tuple[int, float, float]] = []
    in_block = False

    with open(path, "r") as f:
        for line in f:
            if not in_block:
                if line.split()[:1] == ["Step"]:  # header line starts the block
                    in_block = True
                continue

            if "Loop" in line:
                break

            cols = line.split()
            if not cols or cols[0].startswith("#"):
                continue

            # Expect: Step Temp E_pair E_mol TotEng Press
            # Want to keep Step, Temp, and TotEng
            if len(cols) >= 5:
                step = int(cols[0])
                temp = float(cols[1])
                toteng = float(cols[4])
                rows.append((step, temp, toteng))

    if not rows:
        raise ValueError(f"No thermo data found in {path!s}")
    return pd.DataFrame(rows, columns=["Step", "Temp", "TotEng"])


def main(offeror_log: str, nlr_log: str) -> int:
    # Read LAMMPS thermo blocks into pandas df
    offeror_df = read_thermo_block(offeror_log)
    nlr_df = read_thermo_block(nlr_log)

    # Check they are the same length
    assert len(offeror_df) == len(nlr_df), (
        f"Thermo length mismatch: "
        f"{len(offeror_df)} (offeror) vs {len(nlr_df)} (NLR)"
    )

    # Get last entries for comparison 
    # Even given chaotic numerical nature of MD, the first timestep printed 
    # should still agree well
    last_row = nlr_df.iloc[-1]
    nlr_step = int(last_row["Step"])
    nlr_temp = float(last_row["Temp"])
    nlr_toteng = float(last_row["TotEng"])
    last_row = offeror_df.iloc[-1]
    offeror_step = int(last_row["Step"])
    offeror_temp = float(last_row["Temp"])
    offeror_toteng = float(last_row["TotEng"])
    assert nlr_step == offeror_step, f"NLR_Step is {nlr_step} and Offeror_Step is {offeror_step}. Should be equal!"
    assert offeror_temp != 0.0, "Offeror_Temp is zero; something went wrong!."
    assert offeror_toteng != 0.0, "Offeror_TotEng is zero; something went wrong!"

    # Relative errors here will be positive
    rel_error_temp = abs((offeror_temp - nlr_temp) / nlr_temp)
    rel_error_toteng = abs((offeror_toteng - nlr_toteng) / nlr_toteng)

    temp_tol = 1e-4
    toteng_tol = 1e-5
    validated = (rel_error_temp < temp_tol) and (rel_error_toteng < toteng_tol)
    status = "Run validated successfully!" if validated else "Run was NOT validated..."

    print()
    print(f"             {'Step':^4} {'T':>12} {'TotEng':>12}")
    print(f"NLR:         {nlr_step: <4d} {nlr_temp:>12.4f} {nlr_toteng:>12.0f}")
    print(f"Offeror:     {offeror_step: <4d} {offeror_temp:>12.4f} {offeror_toteng:>12.0f}")
    print(f"Rel. error:  {'---': <4} {rel_error_temp:>12.9f} {rel_error_toteng:>12.9f}")
    print('='*50)
    print(status)
    print('='*50)
    print()

    return 0 if validated else 2


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: ./validate.py PATH/lammps_output.log NLR-results/medium_validation.log")
        raise SystemExit(1)
    raise SystemExit(main(sys.argv[1], sys.argv[2]))

