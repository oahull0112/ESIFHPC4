#!/usr/bin/env python3
"""
Usage:
  ./collect-results.py path/to/log1 path/to/log2 ...
"""

from __future__ import annotations

import re
import sys
from dataclasses import dataclass
from pathlib import Path


START_PREFIX = "--- Starting run:"


@dataclass(frozen=True)
class RunSummary:
    benchmark: str
    mpi_tasks: int
    nsteps: int
    loop_time_s: float
    cpu_pct: float
    timesteps_per_s: float

    @property
    def s_per_timestep(self) -> float:
        return 1.0 / self.timesteps_per_s


_START_RE = re.compile(r"^--- Starting run:\s*(.*?)\s*---\s*$")
_LOOP_RE = re.compile(
    r"^Loop time of\s+([0-9]*\.?[0-9]+)\s+on\s+\d+\s+procs\s+for\s+(\d+)\s+steps\b"
)
_PERF_RE = re.compile(r"timesteps/s\b")
_PERF_TS_RE = re.compile(r"([0-9]*\.?[0-9]+)\s+timesteps/s\b")
_CPU_RE = re.compile(r"^([0-9]*\.?[0-9]+)%\s+CPU use with\s+(\d+)\s+MPI tasks\b")


def parse_log(path: str | Path) -> RunSummary:
    benchmark: str | None = None
    loop_time_s: float | None = None
    nsteps: int | None = None
    cpu_pct: float | None = None
    mpi_tasks: int | None = None
    timesteps_per_s: float | None = None

    with open(path, "r") as f:
        for line in f:
            line = line.rstrip("\n")

            if benchmark is None and line.startswith(START_PREFIX):
                m = _START_RE.match(line)
                if m:
                    benchmark = m.group(1).strip().split()[0]
                continue

            if loop_time_s is None or nsteps is None:
                m = _LOOP_RE.match(line)
                if m:
                    loop_time_s = float(m.group(1))
                    nsteps = int(m.group(2))
                    continue

            if timesteps_per_s is None and _PERF_RE.search(line):
                m = _PERF_TS_RE.search(line)
                if m:
                    timesteps_per_s = float(m.group(1))
                    continue

            if cpu_pct is None:
                m = _CPU_RE.match(line)
                if m:
                    cpu_pct = float(m.group(1))
                    mpi_tasks = int(m.group(2))
                    continue

    missing = [k for k, v in {
        "benchmark": benchmark,
        "mpi_tasks": mpi_tasks,
        "nsteps": nsteps,
        "loop_time_s": loop_time_s,
        "cpu_pct": cpu_pct,
        "timesteps_per_s": timesteps_per_s,
    }.items() if v is None]

    if missing:
        raise ValueError(f"{path}: missing fields: {', '.join(missing)}")

    assert benchmark is not None
    assert mpi_tasks is not None
    assert nsteps is not None
    assert loop_time_s is not None
    assert cpu_pct is not None
    assert timesteps_per_s is not None

    return RunSummary(
        benchmark,
        mpi_tasks,
        nsteps,
        loop_time_s,
        cpu_pct,
        timesteps_per_s,
    )


def main(paths: list[str]) -> int:
    print(f"Processing the file paths: {paths}\n\n")

    print(
        "Benchmark MPItasks Nsteps LoopTime(s) "
        "%CPUusage Performance(timesteps/s) Performance(s/timestep)"
    )

    for p in paths:
        try:
            s = parse_log(p)
        except Exception as e:
            print(f"[skip] {e}")
            continue

        print(
            f"{s.benchmark:<8} "
            f"{s.mpi_tasks:>6d} "
            f"{s.nsteps:>6d} "
            f"{s.loop_time_s:>10.3f} "
            f"{s.cpu_pct:>5.1f} "
            f"{s.timesteps_per_s:>8.3f} "
            f"{s.s_per_timestep:>8.4f}"
        )


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: ./collect-results.py file1.log file2.log ...")
        raise SystemExit(1)
    main(sys.argv[1:])

