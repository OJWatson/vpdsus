# Mechanistic models (odin2)

This package contains mechanistic models using `{odin2}` + `{dust2}`.

## CI / dependency resolution

The mechanistic stack depends on `{odin2}` and `{dust2}` from mrc-ide
r-universe / GitHub.

To use the mechanistic helpers locally, install from the mrc-ide r-universe
repository (recommended):

```r
install.packages(
  c("odin2", "dust2"),
  repos = c("https://mrc-ide.r-universe.dev", "https://cloud.r-project.org")
)
```

If you prefer strict pinning, you can install from GitHub at a specific ref, e.g.
with `{remotes}`:

```r
# install.packages("remotes")
remotes::install_github("mrc-ide/odin2")
remotes::install_github("mrc-ide/dust2")
```

## Pinning

If you need strict reproducibility for mechanistic work, pin GitHub remotes in
`DESCRIPTION` by appending `@<sha>` (or tag) in `Remotes:`.

## Package compilation workflow

This package uses the official odin package workflow:

```r
odin2::odin_package(".")
```

This reads `inst/odin/*.R` and generates package bindings under:

- `inst/dust/`
- `src/`
- `R/dust.R`

## Convenience adapters

A few helpers are provided to prepare model inputs without requiring `{odin2}`:

- `odin2_inputs_from_tibble()`: year-keyed tibble → `inputs=` list aligned to `times`
- `odin2_balance_inputs_from_panel()`: panel (`iso3`, `year`, `births`, `coverage`, `cases`) → balance-model inputs

These are useful for building and validating inputs before running any mechanistic code.

## Calibration helpers

- `calibrate_rho_case_balance()`: solve for `rho` in the case-balance recurrence to match a target susceptible count at a chosen year.

## Opt-in execution in CI

The mechanistic vignette and mechanistic tests run when
`VPDSUS_BUILD_ODIN2_VIGNETTE=1`.

This keeps standard R CMD check runs CI-safe.
