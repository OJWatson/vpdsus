```pm-status
milestone: M7
state: running
headSha: 8b7bf56af1bdbcd9a317b0f2114a924e5a4a026c
ciRunUrl: https://github.com/OJWatson/vpdsus/actions/runs/21941026179
updatedAtUtc: 2026-02-12T09:32:45Z
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
- Next step: monitor CI for `d431862` and confirm R-CMD-check + pkgdown are green (they were failing due to missing optional `{odin2}`/`{dust2}` repos on Windows).
