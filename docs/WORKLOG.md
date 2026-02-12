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
