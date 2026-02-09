# Mechanistic models (odin2)

This package contains optional mechanistic model scaffolding using `{odin2}`.

## CI / dependency resolution

The mechanistic stack depends on `{odin2}` and `{dust2}` which are **not on CRAN**.

To keep CI (and users) able to install dependencies reproducibly, we declare the
mrc-ide r-universe repository in `DESCRIPTION`:

- `Additional_repositories: https://mrc-ide.r-universe.dev`

This makes `{odin2}` and `{dust2}` discoverable to dependency solvers such as
`pak` (used by `r-lib/actions/setup-r-dependencies@v2`). Note that `pak` does
*not* automatically install GitHub `Remotes:`; it needs either CRAN or an
additional repository such as r-universe.

If you get errors like "Can't find package called dust2", check that:

1. `DESCRIPTION` still contains the `Additional_repositories` line above.
2. The r-universe repo is reachable from the runner/network.

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
