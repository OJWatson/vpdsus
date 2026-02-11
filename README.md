# vpdsus

`vpdsus` is an R package to:

- retrieve WHO Global Health Observatory (GHO) immunisation **coverage** and reported **cases**,
- combine them with demography,
- estimate vaccine-preventable disease (VPD) susceptibility via progressive methods (A–D), and
- produce WHO-style risk ranking plots and modelling-ready outputs.

## What it does

`vpdsus` helps you:

- fetch WHO GHO immunisation **coverage** and reported **cases** time series,
- join them to demography into a country-year panel,
- estimate susceptibility using a small set of progressive methods, and
- produce WHO-style ranking plots and modelling-ready outputs.

## Supported antigens / diseases (current scope)

**Minimum verified defaults** (intended to work out-of-the-box via `vpd_indicators()`):

- **Coverage (antigens):** `MCV1`, `MCV2` *(measles-containing vaccine dose 1/2)*
- **Cases (diseases):** `measles`

Other antigens/diseases may work by supplying an explicit `indicator_code`.

Notes:

- WHO GHO indicator codes can be discovered with `gho_find_indicator()` and overridden in `get_coverage(..., indicator_code=)` / `get_cases(..., indicator_code=)`.
- Defaults will remain conservative: if a mapping is not verified, it should not be used implicitly.

## Installation

```r
# install.packages("remotes")
remotes::install_github("OJWatson/vpdsus")
```

### Optional dependencies (non-CRAN)

Some optional features rely on packages not on CRAN (e.g. the mechanistic odin2 stack).
These are **not required** for the core workflow.

If you want mechanistic functionality, install `odin2` and `dust2` from the mrc-ide r-universe:

```r
options(repos = c(
  getOption("repos"),
  "mrc-ide" = "https://mrc-ide.r-universe.dev"
))

install.packages(c("odin2", "dust2"))
```

## Quick start (example data)

```r
library(vpdsus)

panel <- vpdsus_example_panel()

sA <- estimate_susceptible_static(panel, coverage_col = "coverage", pop_col = "pop_0_4")
rank <- risk_rank(panel = panel, suscept = sA)

plot_coverage_rank(rank)
plot_susceptible_rank(rank)
```

## Reproduce (targets pipeline)

A small `targets` pipeline scaffold lives in [`analysis/targets/_targets.R`](analysis/targets/_targets.R) and runs on shipped example data.

```r
# install.packages("targets")
setwd("analysis/targets")

targets::tar_make()

# Inspect outputs
targets::tar_read(coverage_plot)
targets::tar_read(susceptible_plot)
```

## Reproducibility + optional features

- Data access helpers are cache-aware (local JSON caching for WHO GHO responses).
- Vignettes are designed to run quickly using shipped example datasets.

### Demography sources

`get_demography()` supports:

- `source = "example"` (default): uses shipped example data (no external dependencies)
- `source = "fixture_wpp"`: uses a tiny shipped WPP-like fixture (deterministic; no external dependencies)
- `source = "wpp"`: uses `{wpp2024}` if installed (optional)

### Non-CRAN Suggests

This package has optional features that use packages not on CRAN (currently including
`odin2`, `dust2`, and `wpp2024`). CI is configured to keep checks green without forcing
installation of Suggests (i.e. `_R_CHECK_FORCE_SUGGESTS_=false`).

Mechanistic functionality (odin2/dust2) is additionally guarded behind
`VPDSUS_BUILD_ODIN2_VIGNETTE=1`.

## License

MIT.
