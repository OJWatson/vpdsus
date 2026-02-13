# CRAN submission checklist (vpdsus)

This is a working checklist for an optional CRAN submission (ROADMAP M8).

## 1. `R CMD check --as-cran`

- [ ] Prefer running checks on a tarball built by `R CMD build` (or `devtools::build()`), e.g.
  - `R CMD build .`
  - `R CMD check --as-cran vpdsus_*.tar.gz`

- [ ] Run `R CMD check --as-cran` on:
  - [ ] Linux
  - [ ] macOS
  - [ ] Windows
- [ ] Target: **0 ERROR / 0 WARNING** and **minimise NOTE**.

## 2. DESCRIPTION / dependencies

- [ ] No hard dependency on non-CRAN packages.
- [ ] Re-check `Imports`/`Depends`/`LinkingTo` are all CRAN.
- [ ] **Potential friction:** non-CRAN packages in `Suggests`.
  - If `odin2` / `dust2` remain in `Suggests`, CRAN checks may emit a NOTE like:
    - "Namespace dependency not required" / "Suggested package not available".
  - Options if submitting to CRAN:
    - remove them from `Suggests`, or
    - move mechanistic functionality behind `Suggests` that are available on CRAN, or
    - keep them but accept/justify the NOTE (likely not acceptable if they are unavailable on CRAN).
- [ ] Consider whether `Additional_repositories` is acceptable for CRAN submission.
  - If not, remove it for the CRAN build.

## 3. Documentation / examples

- [ ] All examples run within time/memory limits.
- [ ] Vignettes do not require internet by default.
- [ ] Optional features that need non-CRAN packages are clearly gated (env var / `requireNamespace()`), and do not run during CRAN checks.

## 4. Licensing / URLs / notes

- [ ] All URLs are valid.
- [ ] License fields correct.
- [ ] No accidental large files included in the tarball.

## 5. Submission artifacts

- [ ] Update `cran-comments.md` for the submission.
- [ ] Tag an rc (e.g. `v0.0.2-rc1`) and final release tag if submitting.
