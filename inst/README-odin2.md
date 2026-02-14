# Mechanistic models (odin2)

This package contains optional mechanistic model scaffolding using `{odin2}`.

## CI / dependency resolution

The mechanistic stack depends on `{odin2}` and `{dust2}` which are **not on CRAN**.

**Policy:** these packages are treated as *optional, external dependencies* and are
not listed in `DESCRIPTION` (to keep the base install CRAN-friendly).

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

## Optional pinning

If you need strict reproducibility for mechanistic work, you can pin GitHub
remotes in `DESCRIPTION` by appending `@<sha>` (or a tag) in the `Remotes:`
field, e.g. `mrc-ide/dust2@<sha>`. This is optional; by default we rely on the
r-universe binaries/source at install time.

## Convenience adapters

A few helpers are provided to prepare model inputs without requiring `{odin2}`:

- `odin2_inputs_from_tibble()`: year-keyed tibble → `inputs=` list aligned to `times`
- `odin2_balance_inputs_from_panel()`: panel (`iso3`, `year`, `births`, `coverage`, `cases`) → balance-model inputs

These are useful for building and validating inputs before running any mechanistic code.

## Calibration helpers

- `calibrate_rho_case_balance()`: solve for `rho` in the case-balance recurrence to match a target susceptible count at a chosen year.

## Opt-in execution

The mechanistic vignette and mechanistic tests are **opt-in** and will only run
when:

- `{odin2}` is installed, and
- `VPDSUS_BUILD_ODIN2_VIGNETTE=1`

This keeps standard R CMD check runs CI-safe.
