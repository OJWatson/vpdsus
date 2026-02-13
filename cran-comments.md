# CRAN comments

## Test environments

- local: Ubuntu 22.04.5 LTS, R 4.5.2
- GitHub Actions: (fill in)

## R CMD check results

- `R CMD check --as-cran --no-manual`: 0 errors ✔ | 0 warnings ✔ | 0 notes ✔ (local)

## Reverse dependencies

- (fill in; usually none for first submission)

## Notes for CRAN

- This is an initial submission.
- The package optionally suggests non-CRAN packages (`odin2`, `dust2`) for mechanistic examples; core functionality does not require them.

## Submission checklist (working)

- [ ] `R CMD check --as-cran` clean on Linux/macOS/Windows (no ERROR/WARNING; minimise NOTEs)
- [ ] DESCRIPTION/README comply with CRAN policies (URLs, no external repos required for installation)
- [ ] Vignettes/examples run without network; any optional examples are guarded
- [ ] License files correct
- [ ] Version bump + NEWS entry for submission tag (e.g. `v0.0.2-rc1`)
