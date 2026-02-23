# Conflict + measles panel pipeline

This directory adds a reproducible Python ETL + merge + starter analysis workflow to combine conflict exposure with the existing `vpdsus` measles/vaccine panel.

## Data sources

### 1) Conflict events (primary)
- **Source**: UCDP Georeferenced Event Dataset (GED), Global v25.1
- **URL used by pipeline**: `https://ucdp.uu.se/downloads/ged/ged251-csv.zip`
- **Unit in raw data**: event-day-location
- **Coverage**: 1989-2024, global (countries with organized violence events)
- **License / terms note**:
  - UCDP download center requests citation of UCDP dataset papers.
  - UCDP website footer states: "Except where otherwise noted, content on this site is licensed under CC BY 4.0."
  - Always include UCDP-recommended citations when publishing outputs.

### 2) Vaccine + measles panel (existing in repo)
- **Source table**: `inst/extdata/example_panel_measles_global.csv`
- **Current provenance**: WHO GHO indicators + World Bank demography (see `inst/extdata/example_panel_measles_global.PROVENANCE.md`)
- **Unit**: country-year

## Why annual merge (and monthly availability)
- Conflict ETL produces **monthly country panel** first (preferred granularity):
  - `ucdp_ged_country_monthly_v251.csv`
- Existing vaccine + measles panel is annual, so merge is performed at **country-year**:
  - `measles_vaccine_conflict_panel_annual.csv`

## Pipeline steps

### 0) Environment
From repo root:

```bash
python -m pip install -r analysis/conflict/requirements.txt
```

### 1) Build conflict panels + merged panel

```bash
python analysis/conflict/run_conflict_etl.py --workdir /home/kana/git/vpdsus
```

This will:
1. Download/cache UCDP GED zip at `analysis/data-raw/conflict/ged251-csv.zip`
2. Parse/harmonize dates and country IDs (to ISO3)
3. Run QA checks (duplicates, date parsing, year/date mismatch, ID mapping issues)
4. Build:
   - monthly conflict panel
   - annual conflict panel
5. Merge annual conflict panel with `vpdsus` country-year panel (join keys: `iso3`, `year`)
6. Export data dictionary and QA summary JSON

### 2) Run starter exploratory analysis

```bash
python analysis/conflict/run_conflict_analysis.py --workdir /home/kana/git/vpdsus
```

This writes summary tables, plots, and basic model outputs under `analysis/outputs/conflict/`.

## Merge logic
- Join type: **left join** from vaccine/case panel to conflict annual panel
- Join keys: `iso3`, `year`
- Conflict coverage flag: `conflict_data_available` is `TRUE` only for years within UCDP GED range (1989-2024)
- For rows where conflict data are available but no event row exists, conflict metrics are set to 0
- For years outside conflict coverage window, conflict metrics remain `NA`

## Output files (primary)
- `analysis/outputs/conflict/ucdp_ged_country_monthly_v251.csv`
- `analysis/outputs/conflict/ucdp_ged_country_annual_v251.csv`
- `analysis/outputs/conflict/measles_vaccine_conflict_panel_annual.csv`
- `analysis/outputs/conflict/measles_vaccine_conflict_data_dictionary.csv`
- `analysis/outputs/conflict/conflict_merge_qa_summary.json`

Starter analysis outputs:
- `analysis_summary_trends_by_year.csv`
- `analysis_conflict_exposure_distribution.csv`
- `analysis_model_summaries.txt`
- `analysis_model_coefficients.csv`
- `analysis_caveats.md`
- plots: `plot_*.png`

## Schema notes
See `measles_vaccine_conflict_data_dictionary.csv` for full variable-level definitions.

Key added conflict fields:
- `conflict_events_total`
- `conflict_fatalities_best`, `conflict_fatalities_high`, `conflict_fatalities_low`
- `conflict_state_based_events`, `conflict_non_state_events`, `conflict_one_sided_events`
- `conflict_any_event`, `conflict_any_fatality`
- `conflict_data_available`

Derived outcome helper:
- `measles_incidence_per_100k`

## Limitations and assumptions
- UCDP GED captures organized violence events; it is not a complete measure of all insecurity/disruption.
- Country-level annual merge can mask subnational and short-run effects.
- Measles case reporting quality likely varies with health-system disruption (including conflict), potentially biasing observed associations.
- The starter models are descriptive/associational and not causal.
