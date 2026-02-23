# vpdsus

`vpdsus` is an R package for building reproducible country-year panels for
vaccine-preventable disease (VPD) surveillance, susceptibility estimation, and
outbreak risk modelling.

It is organised around a stepped workflow:

1. Discover indicators (WHO GHO)
2. Retrieve vaccination coverage and reported cases
3. Combine with demography to build a harmonised panel
4. Estimate susceptible proportions (multiple methods)
5. Validate panel schema and key data constraints
6. Rank and visualise risk in WHO-style outputs
7. Mechanistic susceptibility inference hooks (odin2/dust2)

## Installation

Install from GitHub:

```r
# install.packages("remotes")
remotes::install_github("OJWatson/vpdsus")
```

## Quick start (global example panel)

The package ships a global measles-focused country-year panel (all available
years, worldwide coverage/cases + demography fields) for end-to-end learning
without live downloads:

```r
library(vpdsus)

panel <- vpdsus_example_panel()

suscept <- estimate_susceptible_static(
  panel,
  coverage_col = "coverage",
  pop_col = "pop_0_4"
)

rank <- risk_rank(panel, suscept, window_years = 3, year_end = 2020)
plot_coverage_rank(rank, top_n = 10)
plot_susceptible_rank(rank, top_n = 10)
```

## First project workflow (recommended)

For a first project, use this path:

1. Run an end-to-end demo on bundled data:

```sh
make first-project
```

2. Read outputs in `analysis/outputs/first_project/`:
- `rank_table.csv`
- `model_coefficients.csv`
- `coverage_rank_top10.png`
- `susceptible_rank_top10.png`

3. Then work through vignettes in order:
- `data_access`
- `susceptibility_simple`
- `outbreak_models`
- `mechanistic_odin2`

## Tutorials (vignettes)

Vignettes are intended to be **offline-friendly**: they should run without live downloads.

- `vignette("data_access", package = "vpdsus")`: indicator discovery + coverage/cases access
- `vignette("susceptibility_simple", package = "vpdsus")`: susceptibility methods + ranking parameters
- `vignette("outbreak_models", package = "vpdsus")`: modelling panel + baseline models + evaluation
- `vignette("mechanistic_odin2", package = "vpdsus")`: mechanistic workflow

Live data acquisition and full report pipelines belong under `analysis/`.

## Indicator defaults

Verified defaults via `vpd_indicators()`:

- Coverage: `MCV1`, `MCV2`
- Cases: `measles`

You can discover WHO indicator codes with `gho_find_indicator()` and override them in `get_coverage()` and `get_cases()`.

## Column conventions in the standard panel

- `coverage`: vaccination coverage as a proportion in `[0, 1]`
- `cases`: reported cases (integer, may be missing)
- `year`: calendar year
- `iso3`: country ISO3 code
- population columns are named `pop_*` (e.g. `pop_0_4`, `pop_total`)

Use `panel_validate()` to check schema and value ranges before downstream
susceptibility/modelling steps.

## Mechanistic setup (odin2 + dust2)

Mechanistic models are first-class in this package and are compiled into the
package binary using `odin2::odin_package()`.

- odin source files live in `inst/odin/`
- generated C++/R bindings live in `inst/dust/`, `src/`, and `R/dust.R`

After editing any file under `inst/odin/`, regenerate bindings:

```sh
Rscript scripts/update_odin_models.R
```

To rebuild the shipped global example panel from live WHO/World Bank sources:

```sh
Rscript scripts/rebuild_example_panel_full.R
```

## Reproducibility and checks

From the repository root:

```sh
make test
make check
make site
```

To test that vignettes can build in an offline-friendly mode (best-effort):

```sh
./scripts/build_vignettes_offline.sh
```

To reproduce the example analysis artefacts (table + plots):

```sh
make reproduce
```

Outputs are written to `analysis/outputs/example/`.

## Conflict + measles integration workflow (Python)

A reproducible conflict ETL and merge workflow is available under `analysis/conflict/`.
It builds monthly and annual country conflict exposure panels (UCDP GED), merges
annual conflict features into the existing measles/vaccine panel, and produces
starter exploratory outputs.

```sh
python -m pip install -r analysis/conflict/requirements.txt
python analysis/conflict/run_conflict_etl.py --workdir /home/kana/git/vpdsus
python analysis/conflict/run_conflict_analysis.py --workdir /home/kana/git/vpdsus
```

See `analysis/conflict/README.md` for source documentation, merge logic,
schema, QA checks, and limitations.

## License

MIT.
