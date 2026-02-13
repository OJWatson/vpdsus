```pm-status
milestone: M7
state: complete
headSha: 28262a6570c5d0bef8483d15bf4745a6760ccb5f
ciRunUrl: https://github.com/OJWatson/vpdsus/actions/runs/21946714629
updatedAtUtc: 2026-02-13T05:06:20Z
```

Note: earlier green gate for a prior head was R-CMD-check https://github.com/OJWatson/vpdsus/actions/runs/21916538155.

Note: current git HEAD may include docs-only commits; `headSha` above tracks the last non-doc change.

## Next steps (M7)

- (Done) Local as-cran check: ran `R CMD check --as-cran --no-manual` with Suggests not forced.
  - Remaining expected NOTES: non-CRAN Suggests (resolved via `Additional_repositories`) + "unable to verify current time" can occur in sandboxed environments.
- (Done) Verify pkgdown/site deploy is stable (builds into `site/`; `docs/` is reserved for markdown).
  - Verified locally via `pkgdown::build_site(override = list(destination = "site"), preview = FALSE)`.
- (Done) Expand vignettes to teach the workflow end-to-end (data access → susceptibility → ranking → modelling), including key columns/parameters.
  - Added a short end-to-end modelling example linking the susceptibility estimate into `make_modelling_panel()` / `fit_outbreak_models()` and showing how to inspect predicted probabilities.
- (Done) Removed the `Remotes` field from DESCRIPTION and relied on `Additional_repositories` + README guidance for optional r-universe extras.
- (Done) Cut GitHub release + tag `v0.0.1` from `28262a6` (CI green: status checks 5/5) and published release notes.
