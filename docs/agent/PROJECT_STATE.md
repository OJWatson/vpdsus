# Project state — vpdsus

Status: active
Default branch: main

## Roadmap anchor

See `docs/internal/vpdsus_redevelopment_spec_md.md` for the binding redevelopment specification.

## Current milestone

M1 — Data access (WHO coverage + cases) with verifiable mappings.

## Notes

- `get_country_metadata()` implemented (supports offline fixture + live API with caching) to provide ISO3 → country + WHO region mappings.
- `vpd_indicators()` now distinguishes verified defaults vs reference-only (unverified) entries; unverified mappings are not used implicitly.
- Package vignettes must be able to build offline (no live data downloads in vignettes).
- Live data acquisition and full reports belong under `analysis/`.
- Internal planning/spec documents are quarantined under `docs/internal/`.
