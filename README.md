# vpdsus

`vpdsus` is an R package for building simple, reproducible country–year panels for
vaccine-preventable disease (VPD) surveillance and risk ranking.

It supports:

- WHO Global Health Observatory (GHO) data access for immunisation **coverage** and reported **cases**
- panel construction (coverage + cases + demography)
- susceptibility estimation (progressive methods)
- WHO-style ranking plots and modelling-ready outputs

## Installation

```r
# install.packages("remotes")
remotes::install_github("OJWatson/vpdsus")
```

### Optional (mechanistic modelling + inference hooks)

`vpdsus` has an **opt-in** mechanistic scaffold built around `{odin2}` + `{dust2}`.
These packages are **not on CRAN** and are listed in `Suggests`, so they are not
required for installation, `R CMD check`, or the default vignettes/tests.

Install them from r-universe:

```r
options(repos = c(
  getOption("repos"),
  "mrc-ide" = "https://mrc-ide.r-universe.dev"
))
install.packages(c("odin2", "dust2"))
```

To **execute** the mechanistic vignette and the opt-in integration test locally,
set:

```r
Sys.setenv(VPDSUS_BUILD_ODIN2_VIGNETTE = "1")
```

Then run the vignette `vignette("mechanistic_odin2", package = "vpdsus")` (or
re-run checks/tests).

## Quick start (shipped example data)

```r
library(vpdsus)

panel <- vpdsus_example_panel()

# Method A: static susceptibility estimate
suscept <- estimate_susceptible_static(panel, coverage_col = "coverage", pop_col = "pop_0_4")

# Risk ranking + plots
rank <- risk_rank(panel, suscept, window_years = 3, year_end = 2020)
plot_coverage_rank(rank, top_n = 10)
plot_susceptible_rank(rank, top_n = 10)
```

## What the main columns mean

In the standard panel used throughout the package:

- `coverage`: vaccination coverage as a proportion in `[0, 1]`
- `cases`: reported cases (integer, may be missing)
- `year`: calendar year
- `iso3`: country ISO3 code
- population columns are named `pop_*` (e.g. `pop_0_4`, `pop_total`)

## Tutorials (vignettes)

- `vignette("data_access", package = "vpdsus")`: indicator discovery + coverage/cases access
- `vignette("susceptibility_simple", package = "vpdsus")`: susceptibility + ranking parameters (`window_years`, `year_end`) + risk categories
- `vignette("outbreak_models", package = "vpdsus")`: modelling panel + baseline model fit + evaluation

## Indicator defaults (current verified scope)

Verified defaults via `vpd_indicators()`:

- Coverage: `MCV1`, `MCV2`
- Cases: `measles`

You can discover WHO indicator codes with `gho_find_indicator()` and override them in
`get_coverage(..., indicator_code = )` and `get_cases(..., indicator_code = )`.

## Reproducibility and local checks

For a release-style check, prefer the base toolchain:

```sh
R CMD build .
R CMD check --as-cran vpdsus_*.tar.gz
```

Notes:

- Optional dependencies in `Suggests` (e.g. `{odin2}` / `{dust2}`) remain **opt-in**.
  The mechanistic vignette and its integration test only run when
  `VPDSUS_BUILD_ODIN2_VIGNETTE=1` is set.
- This package supports optional non-CRAN extras (e.g. `{odin2}` / `{dust2}` via
  r-universe). Ensure you have the r-universe repo configured (see above) if you
  want to install those packages locally.
- In some environments you may see benign NOTES such as "unable to verify current time".

## Reproduce (targets pipeline scaffold)

A small `{targets}` scaffold lives in `analysis/targets/_targets.R`.

```r
# install.packages("targets")
setwd("analysis/targets")
targets::tar_make()
```

## License

MIT.
