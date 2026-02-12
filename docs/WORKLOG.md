# Work log

Short, append-only notes intended to preserve continuity across short-lived builder runs.

Guidelines:
- One dated bullet per meaningful action.
- Record check/CI failures (link + 1–2 lines) and the next concrete step.
- Keep this file small.

- 2026-02-12: Marked M7 as running (CI green) and expanded `vignettes/outbreak_models.Rmd` to explain the default time split + interpretation of accuracy/Brier.
- 2026-02-12: Fixed `evaluate_models()` prediction robustness by aligning test-set factor encodings with the trained model, and extended `vignettes/outbreak_models.Rmd` to show how to inspect predicted probabilities.
- 2026-02-12: Clarified optional `{odin2}`/`{dust2}` dependencies and the opt-in `VPDSUS_BUILD_ODIN2_VIGNETTE=1` gating for mechanistic vignette/tests in README.
- 2026-02-12: Removed non-installable `{wpp2024}` from Suggests/Remotes and dropped `source="wpp"` from `get_demography()` so `R CMD check --as-cran --no-manual` runs without errors.
- 2026-02-12: Documented the expected `R CMD check --as-cran` NOTE for `Remotes` (optional `{odin2}` / `{dust2}` via r-universe) in README.
- 2026-02-12: Dropped `Remotes` from DESCRIPTION (keep `Additional_repositories`) and updated README notes; local `R CMD check --as-cran --no-manual` now avoids the `Remotes` NOTE.
- 2026-02-12: Fixed CI dependency resolution for optional `{odin2}`/`{dust2}` by adding `extra-repositories: https://mrc-ide.r-universe.dev` to GitHub Actions workflows (R-CMD-check/pkgdown/lint).
- 2026-02-12: Removed unsupported `extra-repositories` input from `r-lib/actions/setup-r-dependencies@v2` in CI workflows (it was breaking all matrix jobs with "Unexpected input(s) 'extra-repositories'").
- 2026-02-12: Fixed CI failure (https://github.com/OJWatson/vpdsus/actions/runs/21942187968) where `setup-r-dependencies@v2` was given `dependencies: '"hard"'` / `dependencies: '"all"'`; restored the intended values `dependencies: hard` and `dependencies: all`.
- 2026-02-12: Updated docs/STATUS.md to track CI run https://github.com/OJWatson/vpdsus/actions/runs/21942468631 after pushing workflow quoting fix.
