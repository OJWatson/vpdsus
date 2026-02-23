#!/usr/bin/env python3
"""Conflict + measles panel ETL utilities.

Primary source: UCDP GED Global v25.1 event-level data.
"""

from __future__ import annotations

import io
import json
import zipfile
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Tuple

import country_converter as coco
import numpy as np
import pandas as pd
import requests

UCDP_GED_URL = "https://ucdp.uu.se/downloads/ged/ged251-csv.zip"


@dataclass
class ConflictQA:
    raw_rows: int
    unique_event_ids: int
    duplicate_event_id_rows: int
    date_parse_failures: int
    iso3_missing_rows: int
    year_date_mismatch_rows: int
    negative_best_rows: int
    min_year: int
    max_year: int
    n_countries: int

    def to_dict(self) -> Dict[str, int]:
        return {
            "raw_rows": self.raw_rows,
            "unique_event_ids": self.unique_event_ids,
            "duplicate_event_id_rows": self.duplicate_event_id_rows,
            "date_parse_failures": self.date_parse_failures,
            "iso3_missing_rows": self.iso3_missing_rows,
            "year_date_mismatch_rows": self.year_date_mismatch_rows,
            "negative_best_rows": self.negative_best_rows,
            "min_year": self.min_year,
            "max_year": self.max_year,
            "n_countries": self.n_countries,
        }


def ensure_dir(path: Path) -> None:
    path.mkdir(parents=True, exist_ok=True)


def download_ucdp_ged(url: str = UCDP_GED_URL, cache_path: Path | None = None, timeout: int = 180) -> Path:
    """Download UCDP GED zip to cache_path (or temp path in cwd)."""
    if cache_path is None:
        cache_path = Path("analysis/data-raw/conflict/ged251-csv.zip")

    ensure_dir(cache_path.parent)

    if cache_path.exists() and cache_path.stat().st_size > 0:
        return cache_path

    resp = requests.get(url, timeout=timeout)
    resp.raise_for_status()
    cache_path.write_bytes(resp.content)
    return cache_path


def load_ged_zip(zip_path: Path) -> pd.DataFrame:
    """Read GED CSV from the downloaded zip file."""
    with zipfile.ZipFile(zip_path, "r") as zf:
        csv_names = [n for n in zf.namelist() if n.lower().endswith(".csv")]
        if not csv_names:
            raise ValueError(f"No CSV found in {zip_path}")
        with zf.open(csv_names[0]) as fh:
            df = pd.read_csv(
                fh,
                low_memory=False,
                usecols=[
                    "id",
                    "year",
                    "type_of_violence",
                    "country",
                    "date_start",
                    "date_end",
                    "best",
                    "high",
                    "low",
                ],
            )
    return df


def map_country_to_iso3(country_series: pd.Series) -> pd.Series:
    converter = coco.CountryConverter()
    iso3 = converter.convert(country_series.astype(str).tolist(), to="ISO3", not_found=None)
    out = pd.Series(iso3, index=country_series.index)
    out = out.replace({"not found": np.nan, "": np.nan})
    return out


def harmonize_conflict_events(raw: pd.DataFrame) -> Tuple[pd.DataFrame, ConflictQA]:
    df = raw.copy()

    df["date_start"] = pd.to_datetime(df["date_start"], errors="coerce")
    df["date_end"] = pd.to_datetime(df["date_end"], errors="coerce")
    df["iso3"] = map_country_to_iso3(df["country"])

    # numeric safety
    for col in ["best", "high", "low"]:
        df[col] = pd.to_numeric(df[col], errors="coerce")

    df["event_year_from_date"] = df["date_start"].dt.year
    df["event_month"] = df["date_start"].dt.month
    df["event_period_month"] = df["date_start"].dt.to_period("M").astype("string")

    qa = ConflictQA(
        raw_rows=int(len(df)),
        unique_event_ids=int(df["id"].nunique(dropna=True)),
        duplicate_event_id_rows=int(len(df) - df["id"].nunique(dropna=True)),
        date_parse_failures=int(df["date_start"].isna().sum()),
        iso3_missing_rows=int(df["iso3"].isna().sum()),
        year_date_mismatch_rows=int((df["year"] != df["event_year_from_date"]).fillna(False).sum()),
        negative_best_rows=int((df["best"] < 0).fillna(False).sum()),
        min_year=int(df["year"].min()),
        max_year=int(df["year"].max()),
        n_countries=int(df["iso3"].nunique(dropna=True)),
    )

    # Drop invalid rows for panel construction
    df_clean = df.dropna(subset=["date_start", "iso3", "year", "best"]).copy()
    df_clean["year"] = df_clean["year"].astype(int)
    df_clean["event_month"] = df_clean["event_month"].astype(int)

    return df_clean, qa


def aggregate_conflict_monthly(df_clean: pd.DataFrame) -> pd.DataFrame:
    monthly = (
        df_clean.groupby(["iso3", "year", "event_month"], dropna=False)
        .agg(
            conflict_events_total=("id", "count"),
            conflict_fatalities_best=("best", "sum"),
            conflict_fatalities_high=("high", "sum"),
            conflict_fatalities_low=("low", "sum"),
            conflict_state_based_events=("type_of_violence", lambda s: (s == 1).sum()),
            conflict_non_state_events=("type_of_violence", lambda s: (s == 2).sum()),
            conflict_one_sided_events=("type_of_violence", lambda s: (s == 3).sum()),
        )
        .reset_index()
        .sort_values(["iso3", "year", "event_month"])
    )

    monthly["conflict_any_event"] = (monthly["conflict_events_total"] > 0).astype(int)
    monthly["period"] = pd.PeriodIndex.from_fields(
        year=monthly["year"], month=monthly["event_month"], freq="M"
    ).astype(str)
    return monthly


def aggregate_conflict_annual(monthly: pd.DataFrame) -> pd.DataFrame:
    annual = (
        monthly.groupby(["iso3", "year"], dropna=False)
        .agg(
            conflict_events_total=("conflict_events_total", "sum"),
            conflict_fatalities_best=("conflict_fatalities_best", "sum"),
            conflict_fatalities_high=("conflict_fatalities_high", "sum"),
            conflict_fatalities_low=("conflict_fatalities_low", "sum"),
            conflict_state_based_events=("conflict_state_based_events", "sum"),
            conflict_non_state_events=("conflict_non_state_events", "sum"),
            conflict_one_sided_events=("conflict_one_sided_events", "sum"),
        )
        .reset_index()
        .sort_values(["iso3", "year"])
    )
    annual["conflict_any_event"] = (annual["conflict_events_total"] > 0).astype(int)
    annual["conflict_any_fatality"] = (annual["conflict_fatalities_best"] > 0).astype(int)
    return annual


def load_vpdsus_panel(panel_path: Path) -> pd.DataFrame:
    panel = pd.read_csv(panel_path)
    panel["iso3"] = panel["iso3"].astype(str).str.upper().str.strip()
    panel["year"] = pd.to_numeric(panel["year"], errors="coerce").astype("Int64")
    return panel


def merge_conflict_with_panel(
    vpdsus_panel: pd.DataFrame,
    conflict_annual: pd.DataFrame,
    conflict_year_start: int | None = None,
    conflict_year_end: int | None = None,
) -> pd.DataFrame:
    merged = vpdsus_panel.merge(conflict_annual, on=["iso3", "year"], how="left", validate="m:1")

    if conflict_year_start is None:
        conflict_year_start = int(conflict_annual["year"].min())
    if conflict_year_end is None:
        conflict_year_end = int(conflict_annual["year"].max())

    merged["conflict_data_available"] = merged["year"].between(conflict_year_start, conflict_year_end)

    fill_zero_cols = [
        "conflict_events_total",
        "conflict_fatalities_best",
        "conflict_fatalities_high",
        "conflict_fatalities_low",
        "conflict_state_based_events",
        "conflict_non_state_events",
        "conflict_one_sided_events",
        "conflict_any_event",
        "conflict_any_fatality",
    ]

    for col in fill_zero_cols:
        merged[col] = np.where(
            merged["conflict_data_available"] & merged[col].isna(),
            0,
            merged[col],
        )

    merged["cases"] = pd.to_numeric(merged["cases"], errors="coerce")
    merged["pop_total"] = pd.to_numeric(merged["pop_total"], errors="coerce")
    merged["coverage"] = pd.to_numeric(merged["coverage"], errors="coerce")

    merged["measles_incidence_per_100k"] = np.where(
        (merged["cases"].notna()) & (merged["pop_total"] > 0),
        merged["cases"] / merged["pop_total"] * 100000,
        np.nan,
    )

    merged = merged.sort_values(["iso3", "year"]).reset_index(drop=True)
    return merged


def merged_panel_qa(merged: pd.DataFrame) -> Dict[str, object]:
    dupes = int(merged.duplicated(subset=["iso3", "year"]).sum())
    rows = int(len(merged))
    countries = int(merged["iso3"].nunique())
    min_year = int(merged["year"].min())
    max_year = int(merged["year"].max())

    miss = merged[
        [
            "coverage",
            "cases",
            "pop_total",
            "conflict_events_total",
            "conflict_fatalities_best",
            "measles_incidence_per_100k",
        ]
    ].isna().mean()

    return {
        "rows": rows,
        "countries": countries,
        "min_year": min_year,
        "max_year": max_year,
        "duplicate_iso3_year_rows": dupes,
        "missingness_rate": {k: float(v) for k, v in miss.to_dict().items()},
    }


def write_json(data: Dict[str, object], path: Path) -> None:
    ensure_dir(path.parent)
    path.write_text(json.dumps(data, indent=2, sort_keys=True))


def build_conflict_panels(
    output_dir: Path,
    raw_cache_dir: Path,
    vpdsus_panel_path: Path,
    ucdp_url: str = UCDP_GED_URL,
) -> Dict[str, object]:
    ensure_dir(output_dir)
    ensure_dir(raw_cache_dir)

    zip_path = download_ucdp_ged(ucdp_url, raw_cache_dir / "ged251-csv.zip")
    raw = load_ged_zip(zip_path)
    clean, qa = harmonize_conflict_events(raw)

    monthly = aggregate_conflict_monthly(clean)
    annual = aggregate_conflict_annual(monthly)

    monthly_path = output_dir / "ucdp_ged_country_monthly_v251.csv"
    annual_path = output_dir / "ucdp_ged_country_annual_v251.csv"
    monthly.to_csv(monthly_path, index=False)
    annual.to_csv(annual_path, index=False)

    panel = load_vpdsus_panel(vpdsus_panel_path)
    merged = merge_conflict_with_panel(
        panel,
        annual,
        conflict_year_start=qa.min_year,
        conflict_year_end=qa.max_year,
    )
    merged_path = output_dir / "measles_vaccine_conflict_panel_annual.csv"
    merged.to_csv(merged_path, index=False)

    merged_qa = merged_panel_qa(merged)

    qa_payload = {
        "source": {
            "name": "UCDP Georeferenced Event Dataset (GED) Global v25.1",
            "url": ucdp_url,
            "coverage_year_start": qa.min_year,
            "coverage_year_end": qa.max_year,
        },
        "raw_qa": qa.to_dict(),
        "monthly_panel": {
            "rows": int(len(monthly)),
            "countries": int(monthly["iso3"].nunique()),
            "min_year": int(monthly["year"].min()),
            "max_year": int(monthly["year"].max()),
            "duplicates_iso3_year_month": int(monthly.duplicated(["iso3", "year", "event_month"]).sum()),
        },
        "annual_panel": {
            "rows": int(len(annual)),
            "countries": int(annual["iso3"].nunique()),
            "min_year": int(annual["year"].min()),
            "max_year": int(annual["year"].max()),
            "duplicates_iso3_year": int(annual.duplicated(["iso3", "year"]).sum()),
        },
        "merged_panel": merged_qa,
    }

    qa_path = output_dir / "conflict_merge_qa_summary.json"
    write_json(qa_payload, qa_path)

    return {
        "zip_path": str(zip_path),
        "monthly_path": str(monthly_path),
        "annual_path": str(annual_path),
        "merged_path": str(merged_path),
        "qa_path": str(qa_path),
    }


def build_data_dictionary(output_dir: Path) -> Path:
    dd_path = output_dir / "measles_vaccine_conflict_data_dictionary.csv"
    rows = [
        ("iso3", "string", "ISO3 country code"),
        ("year", "int", "Calendar year"),
        ("country", "string", "Country name from vpdsus panel"),
        ("coverage", "float", "MCV1 coverage proportion [0,1]"),
        ("mcv2", "float", "MCV2 coverage percentage when available"),
        ("cases", "float", "Reported measles cases"),
        ("pop_total", "float", "Total population"),
        ("pop_0_4", "float", "Population age 0-4"),
        ("pop_5_14", "float", "Population age 5-14"),
        ("births", "float", "Estimated births"),
        ("conflict_data_available", "bool", "Year within UCDP GED availability window"),
        ("conflict_events_total", "float", "Total conflict events in country-year"),
        ("conflict_fatalities_best", "float", "Best estimate total fatalities in conflict events"),
        ("conflict_fatalities_high", "float", "High estimate fatalities"),
        ("conflict_fatalities_low", "float", "Low estimate fatalities"),
        ("conflict_state_based_events", "float", "Count of state-based events (type_of_violence=1)"),
        ("conflict_non_state_events", "float", "Count of non-state events (type_of_violence=2)"),
        ("conflict_one_sided_events", "float", "Count of one-sided events (type_of_violence=3)"),
        ("conflict_any_event", "float", "1 if any conflict event in country-year, else 0"),
        ("conflict_any_fatality", "float", "1 if best fatalities > 0 in country-year, else 0"),
        ("measles_incidence_per_100k", "float", "cases / pop_total * 100000"),
    ]
    dd = pd.DataFrame(rows, columns=["variable", "type", "definition"])
    dd.to_csv(dd_path, index=False)
    return dd_path


def read_conflict_and_merged(output_dir: Path) -> Tuple[pd.DataFrame, pd.DataFrame]:
    annual = pd.read_csv(output_dir / "ucdp_ged_country_annual_v251.csv")
    merged = pd.read_csv(output_dir / "measles_vaccine_conflict_panel_annual.csv")
    return annual, merged
