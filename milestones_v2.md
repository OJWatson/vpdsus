# vpdsus — Milestones v2 (re-aligned to PDF spec + high documentation/reproducibility bar)

These milestones are **derived from the PDF’s M0–M7**, but make the definition-of-done explicit and add a stronger reproducibility/artefact requirement.

## Guiding definition of done
A milestone is “done” only when:
- there is a reproducible script/pipeline to generate the claimed artefacts,
- outputs are deterministic where applicable (seeded),
- caching/provenance is explicit (URLs, query params, retrieval date, package version),
- vignettes are either runnable quickly on fixtures, or clearly marked as “full run” with opt-in flags.

---

## M0 — Reset + spec alignment
Deliverables:
- `spec_review_vs_pdf.md` committed.
- README tightened to be user-facing, with explicit “Status vs milestones”.
- Clarify disease/antigen scope list (minimum supported set) in docs.

DoD:
- README has no internal dev chatter; points to pkgdown + vignettes + analysis pipeline.

## M1 — Data access (WHO coverage + cases) with verifiable mappings
Deliverables:
- Verify and document correct GHO indicator codes for supported antigens/diseases.
- Add a small pinned fixture (cached JSON) for at least one indicator query for tests.
- Add tests for:
  - URL construction correctness
  - ISO3 standardisation
  - caching key stability

DoD:
- Data access functions reproducible on fixtures; live calls optional.

## M2 — Demography + panel building (authoritative sources)
Deliverables:
- Implement/verify UN WPP pathway (or explicitly document the chosen source), including births + age-structured population.
- Panel builder produces canonical columns per PDF.

DoD:
- `build_panel()` (or equivalent) can produce a country-year panel from pinned inputs.

## M3 — Susceptibility methods + WHO-style outputs
Deliverables:
- Methods A–D reviewed against PDF definitions; add missing pieces if any.
- Add “golden” rank plot regression test using example data.
- Provide a vignette that produces the intended WHO-style ranking outputs.

DoD:
- `analysis/targets` produces the headline ranking figures deterministically.

## M4 — Outbreak modelling module (research-grade)
Deliverables:
- Multiple outcome definitions (abs vs per-capita vs exceedance), lag sensitivity.
- Clear evaluation (time-split or rolling) + baseline comparisons.
- Output tables/figures suitable for manuscript/presentation.

DoD:
- Pipeline step that generates modelling results + diagnostics.

## M5 — Mechanistic odin2 module (simulation success path)
Deliverables:
- Mechanistic vignette that:
  - compiles at least one template
  - runs a simulation
  - compares trajectories to method D outputs
- Still opt-in for CI (`VPDSUS_BUILD_ODIN2_VIGNETTE=1`).

DoD:
- When enabled, vignette runs cleanly and produces its figures.

## M6 — Optional inference hooks (rho/reporting fraction and/or MCMC)
Deliverables:
- Choose and implement one inference pathway from the PDF:
  - rho calibration / sensitivity (minimum), and
  - optionally a Bayesian/MCMC hook (dust2/odin2 compatible)
- Add clear success criteria + minimal synthetic validation.

DoD:
- Documented inference API and at least one validated example.

## M7 — Public-ready reproducible release
Deliverables:
- “Reproduce from scratch” entrypoint:
  - either a single `targets` plan or a Makefile wrapper
  - writes versioned artefacts to `analysis/outputs/` (or similar)
- Pkgdown site includes:
  - function reference
  - vignettes
  - reproducibility instructions

DoD:
- Fresh environment can reproduce the main figures without manual steps (or with clearly documented credentialed data steps).

