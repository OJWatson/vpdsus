# vpdsus

`vpdsus` is an R package to retrieve WHO Global Health Observatory (GHO) immunisation coverage and reported cases, combine them with demography, estimate vaccine-preventable disease susceptibility via progressive methods (A–E), and produce WHO-style risk ranking plots and modelling outputs.

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

p1 <- plot_coverage_rank(rank)
p2 <- plot_susceptible_rank(rank)

p1
p2
```

## Reproducibility

- Data access functions are cache-aware and record provenance.
- Vignettes are designed to run quickly using shipped example datasets.
- A full end-to-end pipeline scaffold is provided under `analysis/targets/`.

### Non-CRAN Suggests

This package has optional features that use packages not on CRAN (currently including
`odin2`, `dust2`, and `wpp2024`). CI is configured to keep checks green without forcing
installation of Suggests (i.e. `_R_CHECK_FORCE_SUGGESTS_=false`).

Mechanistic functionality (odin2/dust2) is additionally guarded behind
`VPDSUS_BUILD_ODIN2_VIGNETTE=1`.

## License

MIT.
