#!/usr/bin/env python3
"""Build conflict monthly/annual panels and merged measles-vaccine-conflict panel."""

from __future__ import annotations

import argparse
from pathlib import Path

from conflict_pipeline import build_conflict_panels, build_data_dictionary


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser()
    p.add_argument(
        "--workdir",
        type=Path,
        default=Path("."),
        help="Repository root (default: current directory)",
    )
    p.add_argument(
        "--output-dir",
        type=Path,
        default=Path("analysis/outputs/conflict"),
    )
    p.add_argument(
        "--raw-cache-dir",
        type=Path,
        default=Path("analysis/data-raw/conflict"),
    )
    p.add_argument(
        "--panel-path",
        type=Path,
        default=Path("inst/extdata/example_panel_measles_global.csv"),
    )
    return p.parse_args()


def main() -> None:
    args = parse_args()
    workdir = args.workdir.resolve()

    outputs = build_conflict_panels(
        output_dir=(workdir / args.output_dir),
        raw_cache_dir=(workdir / args.raw_cache_dir),
        vpdsus_panel_path=(workdir / args.panel_path),
    )
    dd_path = build_data_dictionary(workdir / args.output_dir)

    print("Built conflict pipeline outputs:")
    for k, v in outputs.items():
        print(f"  - {k}: {v}")
    print(f"  - data_dictionary_path: {dd_path}")


if __name__ == "__main__":
    main()
