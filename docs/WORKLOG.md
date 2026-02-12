# Work log

Short, append-only notes intended to preserve continuity across short-lived builder runs.

Guidelines:
- One dated bullet per meaningful action.
- Record check/CI failures (link + 1–2 lines) and the next concrete step.
- Keep this file small.

- 2026-02-12: Marked M7 as running (CI green) and expanded `vignettes/outbreak_models.Rmd` to explain the default time split + interpretation of accuracy/Brier.
- 2026-02-12: Fixed `evaluate_models()` prediction robustness by aligning test-set factor encodings with the trained model, and extended `vignettes/outbreak_models.Rmd` to show how to inspect predicted probabilities.
