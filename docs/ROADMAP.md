# ROADMAP

This file is the canonical milestone plan.

## Milestones (M0–M8)

### M0 — Repository skeleton and professional scaffolding
- CI green (R-CMD-check, lint, pkgdown)
- User-facing README (scope, install, quick start, reproducibility)
- Clear scope + conservative defaults

### M1 — Data access: WHO coverage and cases
- Verified indicator mappings for the minimum supported scope
- Pinned fixtures + provenance metadata for at least one coverage and one cases query
- Fixture-based tests (URL construction, parsing/standardisation, ISO3 handling, cache-key stability)

### M2 — Demography retrieval and panel building
- A standardised demography accessor (authoritative source or deterministic fixture adapter)
- Panel builder joins coverage/cases/demography into a modelling-ready panel
- Tests for panel builder shape + basic diagnostics

### M3 — Susceptibility estimates v1 + WHO-style outputs
- Minimum susceptibility method runs on shipped example data
- WHO-style ranking/plot output
- Golden regression test on shipped example data

### M4 — Statistical models linking susceptibility to outbreaks
- Modelling panel creation
- Baseline outbreak model fits end-to-end
- Evaluation helper runs; deterministic test asserts shape + stable summary metrics

### M5 — Mechanistic scaffolding in odin2 (simulation, not inference)
- Mechanistic simulation scaffold remains optional/opt-in
- Opt-in mechanistic test/vignette runs end-to-end when enabled

### M6 — Optional inference hooks (reporting fraction and/or MCMC)
- Minimal reporting-fraction hook (rho calibration) usable with mechanistic simulation
- Opt-in end-to-end test/example calibrates rho then simulates

### M7 — Public-ready release (GitHub + pkgdown + full reproducibility)
- Release-readiness checklist passes (local check, site build, docs)
- Clear reproducibility path documented
- CI green on release head

### M8 — CRAN submission (optional)
- Ensure `R CMD check --as-cran` is clean on Linux/macOS/Windows (no ERROR/WARNING; minimise NOTEs)
- Review DESCRIPTION/README for CRAN policies (URLs, non-CRAN Suggests guidance, additional repos)
- Prepare `cran-comments.md` and a submission tag (e.g. `v0.0.2-rc1`)
