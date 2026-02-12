```pm-status
milestone: M7
state: running
headSha: af0ef85cd57b5ffbf42199de140f0302fc16900a
ciRunUrl: https://github.com/OJWatson/vpdsus/actions/workflows/R-CMD-check.yaml
updatedAtUtc: 2026-02-12T11:56:40Z
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
- Next step: wait for CI to go green on `af0ef85` (R-CMD-check/lint/pkgdown); then flip M7 to `done` + cut the release/tag.
