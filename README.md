# vpdsus

`vpdsus` is an R package for building reproducible country–year panels for vaccine-preventable disease (VPD) surveillance, susceptibility estimation, and downstream risk scanning / modelling.

It is organised around a stepped workflow:

1. Discover indicators (WHO GHO)
2. Retrieve vaccination coverage and reported cases
3. Combine with demography to build a harmonised panel
4. Estimate susceptible proportions (multiple methods)
5. Rank and visualise risk in WHO-style outputs
6. (Planned) Mechanistic susceptibility inference using an explicit SIRV model

## Installation

Install from GitHub:

```r
# install.packages("remotes")
remotes::install_github("OJWatson/vpdsus")
```

## Quick start (example panel)

The package ships an example panel for learning the end-to-end workflow without downloading any data:

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

## Tutorials (vignettes)

Vignettes are intended to be **offline-friendly**: they should run without live downloads.

- `vignette("01_data_access", package = "vpdsus")`: indicator discovery + coverage/cases access
- `vignette("02_susceptibility_simple", package = "vpdsus")`: susceptibility methods + ranking parameters
- `vignette("03_outbreak_models", package = "vpdsus")`: modelling panel + baseline models + evaluation
- `vignette("04_mechanistic_odin2", package = "vpdsus")`: mechanistic workflow (under redevelopment)

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

## Reproducibility and checks

From the repository root:

```sh
R CMD check --no-manual
Rscript -e 'pkgdown::build_site()'
```

To test that vignettes can build in an offline-friendly mode (best-effort):

```sh
./scripts/build_vignettes_offline.sh
```

## Redevelopment roadmap

A binding redevelopment specification is included in:

- `docs/internal/vpdsus_redevelopment_spec_md.md`

This roadmap defines the target end-state (including an explicit SIRV mechanistic model and fully tutorial-style vignettes) and the milestone sequence for getting there.

## License

MIT.
