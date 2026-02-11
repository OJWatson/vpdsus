# vpdsus

`vpdsus` is an R package to:

- retrieve WHO Global Health Observatory (GHO) immunisation **coverage** and reported **cases**,
- combine them with demography,
- estimate vaccine-preventable disease (VPD) susceptibility via progressive methods (A–D), and
- produce WHO-style risk ranking plots and modelling-ready outputs.

## Status (PDF spec milestones)

This repository is being aligned to the original PDF plan (“Blueprint for an R package to estimate VPD susceptibility and link it to outbreak risk”).

- Milestone definitions (v2, with explicit DoD): [`milestones_v2.md`](milestones_v2.md)
- Current gap review vs PDF: [`spec_review_vs_pdf.md`](spec_review_vs_pdf.md)

Current implementation status (high-level):

- **M0 (scaffolding + spec alignment):** in progress (this README + milestone/spec docs).
- **M1 (WHO coverage + cases access):** implemented (GHO helpers), indicator mappings need verification/pinning.
- **M2 (demography + panel building):** partial (example demography + optional WPP adapter).
- **M3 (susceptibility + WHO-style outputs):** partial-to-good (methods A–D + ranking plots exist; “golden figure” reproduction pending).
- **M4–M7 (modelling/mechanistic/inference/public reproducibility):** present as scaffolding; not yet at PDF “end-to-end reproducible” bar.

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

### Non-CRAN Suggests

This package has optional features that use packages not on CRAN (currently including
`odin2`, `dust2`, and `wpp2024`). CI is configured to keep checks green without forcing
installation of Suggests (i.e. `_R_CHECK_FORCE_SUGGESTS_=false`).

Mechanistic functionality (odin2/dust2) is additionally guarded behind
`VPDSUS_BUILD_ODIN2_VIGNETTE=1`.

## License

MIT.
