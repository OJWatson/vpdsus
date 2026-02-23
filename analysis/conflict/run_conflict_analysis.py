#!/usr/bin/env python3
"""Exploratory analysis starter for conflict-measles panel."""

from __future__ import annotations

import argparse
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns
import statsmodels.formula.api as smf

sns.set_theme(style="whitegrid")


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser()
    p.add_argument("--workdir", type=Path, default=Path("."))
    p.add_argument("--output-dir", type=Path, default=Path("analysis/outputs/conflict"))
    return p.parse_args()


def main() -> None:
    args = parse_args()
    workdir = args.workdir.resolve()
    out = (workdir / args.output_dir).resolve()
    out.mkdir(parents=True, exist_ok=True)

    panel = pd.read_csv(out / "measles_vaccine_conflict_panel_annual.csv")

    # Keep years where conflict data exists for model summaries.
    panel_model = panel[panel["conflict_data_available"] == True].copy()  # noqa: E712

    panel_model["log_cases_plus1"] = np.log1p(pd.to_numeric(panel_model["cases"], errors="coerce"))
    panel_model["log_fatalities_plus1"] = np.log1p(pd.to_numeric(panel_model["conflict_fatalities_best"], errors="coerce"))
    panel_model["log_pop_total"] = np.log(pd.to_numeric(panel_model["pop_total"], errors="coerce"))

    # Summary trends
    annual = (
        panel_model.groupby("year", as_index=False)
        .agg(
            measles_cases_total=("cases", "sum"),
            conflict_events_total=("conflict_events_total", "sum"),
            conflict_fatalities_best=("conflict_fatalities_best", "sum"),
            countries=("iso3", "nunique"),
        )
    )
    annual.to_csv(out / "analysis_summary_trends_by_year.csv", index=False)

    # Conflict exposure distribution
    exposure = panel_model[["conflict_events_total", "conflict_fatalities_best", "conflict_any_event"]].copy()
    exposure.describe().to_csv(out / "analysis_conflict_exposure_distribution.csv")

    # Plot 1: Global trends over time
    fig, ax1 = plt.subplots(figsize=(10, 5))
    ax2 = ax1.twinx()
    ax1.plot(annual["year"], annual["measles_cases_total"], color="#2c7fb8", label="Measles cases (total)")
    ax2.plot(annual["year"], annual["conflict_fatalities_best"], color="#d95f0e", label="Conflict fatalities (best)")
    ax1.set_xlabel("Year")
    ax1.set_ylabel("Measles cases")
    ax2.set_ylabel("Conflict fatalities")
    ax1.set_title("Global annual measles cases vs conflict fatalities")

    lines1, labels1 = ax1.get_legend_handles_labels()
    lines2, labels2 = ax2.get_legend_handles_labels()
    ax1.legend(lines1 + lines2, labels1 + labels2, loc="upper right")
    fig.tight_layout()
    fig.savefig(out / "plot_global_trends_cases_conflict.png", dpi=150)
    plt.close(fig)

    # Plot 2: Conflict exposure distribution
    fig = plt.figure(figsize=(8, 5))
    sns.histplot(np.log1p(panel_model["conflict_events_total"]), bins=40)
    plt.xlabel("log(1 + conflict events)")
    plt.ylabel("Country-year count")
    plt.title("Distribution of conflict exposure (country-year)")
    plt.tight_layout()
    fig.savefig(out / "plot_conflict_exposure_distribution.png", dpi=150)
    plt.close(fig)

    # Plot 3: Measles incidence by conflict status
    incidence = (
        panel_model.assign(
            measles_incidence_per_100k=pd.to_numeric(panel_model["measles_incidence_per_100k"], errors="coerce")
        )
        .groupby(["year", "conflict_any_event"], as_index=False)
        .agg(mean_incidence_per_100k=("measles_incidence_per_100k", "mean"))
    )
    fig = plt.figure(figsize=(10, 5))
    sns.lineplot(data=incidence, x="year", y="mean_incidence_per_100k", hue="conflict_any_event", palette="Set1")
    plt.xlabel("Year")
    plt.ylabel("Mean measles incidence per 100k")
    plt.title("Mean incidence by conflict exposure status")
    plt.legend(title="Any conflict event", labels=["No", "Yes"])
    plt.tight_layout()
    fig.savefig(out / "plot_incidence_by_conflict_status.png", dpi=150)
    plt.close(fig)

    # Basic transparent models (starter only)
    model_data = panel_model.dropna(
        subset=["log_cases_plus1", "coverage", "log_pop_total", "log_fatalities_plus1", "year"]
    ).copy()

    model1 = smf.ols(
        "log_cases_plus1 ~ conflict_any_event + coverage + log_pop_total + C(year)",
        data=model_data,
    ).fit(cov_type="HC1")

    model2 = smf.ols(
        "log_cases_plus1 ~ log_fatalities_plus1 + coverage + log_pop_total + C(year)",
        data=model_data,
    ).fit(cov_type="HC1")

    with open(out / "analysis_model_summaries.txt", "w", encoding="utf-8") as fh:
        fh.write("Model 1: log(1+cases) ~ any conflict event + coverage + log(pop) + year FE\n")
        fh.write(model1.summary().as_text())
        fh.write("\n\n")
        fh.write("Model 2: log(1+cases) ~ log(1+fatalities) + coverage + log(pop) + year FE\n")
        fh.write(model2.summary().as_text())

    coeffs = pd.concat(
        [
            model1.params.rename("model1"),
            model2.params.rename("model2"),
        ],
        axis=1,
    )
    coeffs.to_csv(out / "analysis_model_coefficients.csv")

    caveats = (
        "# Conflict-measles exploratory analysis caveats\n\n"
        "- These are association models only; they do not identify causal effects.\n"
        "- Conflict variables come from UCDP GED event locations (1989-2024); years outside this range have no conflict coverage.\n"
        "- Measles cases are reported cases and may suffer from under-reporting, especially during conflict.\n"
        "- Country-level annual aggregation masks subnational and within-year dynamics.\n"
        "- No country fixed effects are included in these starter models; add FE/DiD/specification checks in follow-up.\n"
    )
    (out / "analysis_caveats.md").write_text(caveats, encoding="utf-8")

    print("Analysis outputs written to", out)


if __name__ == "__main__":
    main()
