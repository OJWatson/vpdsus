# vpdsus — Spec Review vs PDF plan (VPD susceptibility package plan v0.1, 2026‑02‑07)

This document is a **gap analysis** of the current `OJWatson/vpdsus` repository against the original PDF plan ("Blueprint for an R package to estimate VPD susceptibility and link it to outbreak risk").

## Executive summary

`vpdsus` is **substantially closer to its PDF spec** than `motac` was: it already has a coherent R package, cache-aware WHO GHO access helpers, demography/panel scaffolding, susceptibility methods A–D, basic outbreak-modelling helpers, and an opt-in odin2 mechanistic pathway guarded for CI.

However, relative to the PDF’s stated primary deliverable (“end-to-end analysis pipeline that reproduces the main figures from scratch”) and its high-quality engineering goals, there are still **notable gaps**:

1) **End-to-end reproducibility** currently relies on example data and a minimal `targets` pipeline; it does not yet demonstrate full-from-scratch reproduction on real WHO/UN inputs with versioned artefacts.
2) **Data sources** are implemented via WHO GHO OData endpoints, but the PDF emphasises “authoritative public sources primarily WHO and UN” with careful harmonisation—some of this exists (ISO3 harmonisation, caching), but the full provenance/artefact strategy needs strengthening.
3) **Modelling module** exists but is still lightweight vs the spec’s goal (multiple outcome definitions, model evaluation, clear modelling datasets, and richer diagnostics).
4) **Mechanistic module** exists and is correctly guarded, but the spec expects a clearer “success criteria” path and (optionally) inference hooks; those are not yet at the “paper-quality” bar.
5) **Documentation/site** exists (pkgdown + vignettes), but the “public-ready release” milestone implies a more comprehensive reproducibility story and clearer guidance for a new user.

## What the PDF requires (high-level)

The PDF’s primary deliverable is:
- an installable R package + vignettes, and
- an end-to-end analysis workflow that reproduces “main figures” from scratch.

Milestones in the PDF are M0–M7:
- M0 scaffolding
- M1 data access (WHO coverage + cases)
- M2 demography + panel building
- M3 susceptibility v1 + WHO-style plots
- M4 statistical models linking susceptibility to outbreaks
- M5 mechanistic scaffolding (odin2 simulation)
- M6 optional inference hooks
- M7 public-ready release (pkgdown + full reproducibility)

## Current repository: status vs spec

### M0 — Repository skeleton and professional scaffolding
**Implemented:** yes (CI, lint, tests, pkgdown, vignettes).  
**Notes:** CI is stable; odin2 is opt-in via `VPDSUS_BUILD_ODIN2_VIGNETTE=1` (good).

### M1 — Data access: WHO coverage and cases
**Implemented:** mostly.
- `gho_get()`, `gho_find_indicator()`, `get_coverage()`, `get_cases()` exist.

**Gaps / risks:**
- Indicator mapping defaults (`vpd_indicators()`) look partly placeholder-ish (e.g. `MEASLESCASES`); needs verification against actual GHO codes and/or explicit docs on how to discover the right codes.
- Need explicit acceptance tests that hit the live API (possibly in a non-CRAN CI job) OR pinned cached fixtures with recorded request URLs.

### M2 — Demography retrieval and panel building
**Implemented:** partial.
- Demography module exists (`R/data-demography.R`, `R/panel-build.R`), but a detailed check against PDF’s preferred sources (UN WPP) and fallback strategy is needed.

**Gap:** end-to-end build of a real country-year-age panel from raw sources is not yet demonstrated as a reproducible artefact.

### M3 — Susceptibility estimates v1 + WHO-style plots
**Implemented:** partial-to-good.
- Susceptibility methods exist:
  - A: `estimate_susceptible_static()`
  - B: `estimate_susceptible_cohort()`
  - C: `estimate_susceptible_cohort_ve()`
  - D: `estimate_susceptible_case_balance()` (incl. rho sensitivity)
- Plotting/risk ranking exists (`risk_rank()`, plotting functions, theme).

**Gap:** the PDF emphasises a minimum supported set of diseases/antigens and “WHO-style risk ranking figures”; we should verify the current plots match the intended outputs and add a “golden figure” regression test using pinned example data.

### M4 — Statistical modelling linking susceptibility to outbreaks
**Implemented:** partial.
- `make_modelling_panel()`, `fit_outbreak_models()`, `evaluate_models()` exist.

**Gaps:**
- Broader outcome definitions, model comparisons, and diagnostics (e.g. ROC/AUC, calibration curves, sensitivity to lag choice) are not yet present.
- The PDF implies clean modelling datasets and evaluation; current helpers are a start but not yet research-grade.

### M5 — Mechanistic scaffolding in odin2 (simulation)
**Implemented:** partial.
- odin2 template compilation + dust2 simulation exists and templates are shipped.
- Correctly guarded (Suggests + env var).

**Gaps:**
- Need a clear “mechanistic success” vignette that runs end-to-end when enabled, and produces a small set of sanity-check figures.

### M6 — Optional inference hooks
**Implemented:** minimal.
- Rho calibration work exists (files suggest this direction), but this needs review against the PDF’s requested pathways (reporting fraction, MCMC hooks) and a crisp DoD.

### M7 — Public-ready release (pkgdown + full reproducibility)
**Implemented:** partial.
- Pkgdown site exists.
- Vignettes exist.

**Gaps:**
- “Full reproducibility from scratch” is not yet met: we need a single command pipeline that pulls raw sources (or clearly documented cached inputs), writes versioned artefacts, and regenerates the headline figures.

## Key immediate issues to address

1) **Authoritative, reproducible data artefacts**: decide what is downloaded live vs shipped as pinned fixtures; write provenance metadata.
2) **End-to-end pipeline**: strengthen `analysis/targets/` into a real reproduction pipeline that can (optionally) run from scratch and produce figures/tables.
3) **Modelling evaluation**: expand modelling to include a small set of robust checks consistent with the PDF.

