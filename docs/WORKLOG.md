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
- 2026-02-12: Fixed CI failure (https://github.com/OJWatson/vpdsus/actions/runs/21942187968) where `setup-r-dependencies@v2` was given `dependencies: hard` / `dependencies: all` (interpreted as R symbols); switched to `dependencies: '"hard"'` / `dependencies: '"all"'` so the action passes an R string literal.
- 2026-02-12: Fixed CI failure (https://github.com/OJWatson/vpdsus/actions/runs/21942398114) where `setup-r-dependencies@v2` treated `dependencies: hard` as an R symbol (`object 'hard' not found`) by quoting the input (`dependencies: '"hard"'` / `dependencies: '"all"'`).
- 2026-02-12: Updated docs/STATUS.md to track CI run https://github.com/OJWatson/vpdsus/actions/runs/21942468631 after pushing workflow quoting fix.
- 2026-02-12: Re-added `extra-repositories: https://mrc-ide.r-universe.dev` to `setup-r-dependencies@v2` so pak can resolve optional Suggests (`odin2`, `dust2`) during the pandoc/deps scan on macOS/Windows.
- 2026-02-12: Fixed CI failures on macOS/Windows by only passing `extra-repositories` to `setup-r-dependencies@v2` on Linux in R-CMD-check workflow; pushed `3358aea` and tracking run https://github.com/OJWatson/vpdsus/actions/runs/21943239823.
- 2026-02-12: Fixed CI failure (https://github.com/OJWatson/vpdsus/actions/runs/21943256516) where `setup-r-dependencies@v2` rejects the `extra-repositories` input; removed `extra-repositories` from workflows and pushed `7caeee4` (tracking run https://github.com/OJWatson/vpdsus/actions/runs/21943592138).
- 2026-02-12: Updated `docs/STATUS.md` to reflect the current release-head CI run (`7caeee4`) and the next action (confirm green → mark M7 done/tag release); ran `devtools::test()` locally (PASS).
- 2026-02-12: Fixed R-CMD-check workflow to install only "hard" deps (avoid non-CRAN Suggests like `{odin2}`/`{dust2}` on macOS/Windows); will re-run CI to confirm green.
- 2026-02-12: Added `workflow_dispatch` to the R-CMD-check workflow to allow manual reruns; pushed `af0ef85`.
- 2026-02-12: Fixed R-CMD-check CI failure on macOS by removing an invalid `needs: '"hard"'` input from `setup-r-dependencies@v2`; pushed `b5142fa`.
- 2026-02-12: Updated docs/STATUS.md timestamp + clarified next step: wait for CI outcomes on b5142fa (runs #142/#143 + lint/pkgdown) before flipping M7 to done/tagging.
- 2026-02-12: Fixed CI failures: pkgdown now installs pandoc via apt (avoid setup-pandoc download 500s) and workflows configure CRAN + mrc-ide r-universe via .Rprofile (written in Rscript for Windows) so pak can resolve optional odin2/dust2 during dependency discovery. (Green run: https://github.com/OJWatson/vpdsus/actions/runs/21946714629)
- 2026-02-12: Confirmed commit `28262a6` has successful status checks (5/5), ran `devtools::test()` locally (PASS), and flipped M7 to `done` in docs/STATUS.md; next action is to cut the release/tag.

- 2026-02-13: Cut GitHub release v0.0.1 from release head 28262a6 (CI success: https://github.com/OJWatson/vpdsus/actions/runs/21946714629) and marked M7 complete in docs/STATUS.md.

- 2026-02-13: Verified tag v0.0.1 points to 28262a6 and the GitHub release page exists; updated docs/STATUS.md timestamp + marked release step done.
- 2026-02-13: Post-release tidy: confirmed ROADMAP ends at M7 (no next milestone) and refreshed STATUS timestamp.

- 2026-02-13: Added ROADMAP M8 (optional CRAN submission) and marked M8 as running in docs/STATUS.md.
- 2026-02-13: Drafted `cran-comments.md` template, added it to `.Rbuildignore`, and confirmed local `R CMD check --as-cran --no-manual` is clean (0 errors/warnings/notes).
