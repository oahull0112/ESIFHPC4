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
    offeror_df = read_thermo_block(offeror_log)
    nlr_df = read_thermo_block(nlr_log)

    assert len(offeror_df) == len(nlr_df), (
        f"Thermo length mismatch: "
        f"{len(offeror_df)} (offeror) vs {len(nlr_df)} (NLR)"
    )

    merged = pd.concat(
        [nlr_df[["Temp", "TotEng"]], offeror_df[["Temp", "TotEng"]]],
        axis=1,
        keys=["NLR", "Offeror"],
    )
    merged.columns = ["NLR_Temp", "NLR_TotEng", "Offeror_Temp", "Offeror_TotEng"]

    nlr_temp_avg = float(merged["NLR_Temp"].mean())
    nlr_toteng_avg = float(merged["NLR_TotEng"].mean())
    offeror_temp_avg = float(merged["Offeror_Temp"].mean())
    offeror_toteng_avg = float(merged["Offeror_TotEng"].mean())
    assert offeror_temp_avg != 0.0, "Offeror_Temp average is zero; cannot form relative RMSE."
    assert offeror_toteng_avg != 0.0, "Offeror_TotEng average is zero; cannot form relative RMSE."

    rms_temp = float(np.sqrt(((merged["NLR_Temp"] - merged["Offeror_Temp"]) ** 2).mean()) / offeror_temp_avg)
    rms_toteng = float(
        np.sqrt(((merged["NLR_TotEng"] - merged["Offeror_TotEng"]) ** 2).mean()) / offeror_toteng_avg
    )

    validated = (rms_temp < 1.0e-3) and (rms_toteng < 1.0e-5)
    status = "Run validated successfully!" if validated else "Run was NOT validated..."

    print(f"NLR average T and E: {nlr_temp_avg:.6e} {nlr_toteng_avg:.6e}")
    print(f"Offeror average T and E: {offeror_temp_avg:.6e} {offeror_toteng_avg:.6e}")
    print(f"Relative RMS errors: {rms_temp:.6e} {rms_toteng:.6e}")
    print(status)

    # These file outputs are available, but commented out
    # out_dir = Path(offeror_log).resolve().parent
    # offeror_df.to_csv(out_dir / "thermo.dat", sep=" ", index=False)

    # out_dir = Path(nlr_log).resolve().parent
    # with open(out_dir / "rms_errors.dat", "w") as outfile:
    #     outfile.write(f"NLR average T and E: {nlr_temp_avg:.6e} {nlr_toteng_avg:.6e}\n")
    #     outfile.write(f"Offeror average T and E: {offeror_temp_avg:.6e} {offeror_toteng_avg:.6e}\n")
    #     outfile.write(f"Relative RMS errors: {rms_temp:.6e} {rms_toteng:.6e}\n")
    #     outfile.write(f"{status}\n")

    return 0 if validated else 2


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: ./validate.py PATH/lammps_output.log NLR-results/medium_validation.log")
        raise SystemExit(1)
    raise SystemExit(main(sys.argv[1], sys.argv[2]))

