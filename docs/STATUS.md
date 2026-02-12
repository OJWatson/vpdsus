```pm-status
milestone: M7
state: running
headSha: 1dfceb9f52cfe6d2b35f75624f9368e97261080b
ciRunUrl: https://github.com/OJWatson/vpdsus/actions/runs/21934777155, https://github.com/OJWatson/vpdsus/actions/runs/21934777149, https://github.com/OJWatson/vpdsus/actions/runs/21934777145, https://github.com/OJWatson/vpdsus/actions/runs/21934824875
updatedAtUtc: 2026-02-12T06:51:34Z
```

Note: earlier green gate for a prior head was R-CMD-check https://github.com/OJWatson/vpdsus/actions/runs/21916538155.

Note: current git HEAD may include docs-only commits; `headSha` above tracks the last non-doc change.

## Next steps (M7)

- (Done) Local as-cran check: ran `R CMD check --as-cran` with Suggests not forced.
  - Remaining expected NOTES: `Remotes` field + non-CRAN Suggests; "unable to verify current time" can occur in sandboxed environments.
- (Done) Verify pkgdown/site deploy is stable (builds into `site/`; `docs/` is reserved for markdown).
  - Verified locally via `pkgdown::build_site(override = list(destination = "site"), preview = FALSE)`.
- Expand vignettes to teach the workflow end-to-end (data access → susceptibility → ranking → modelling), including key columns/parameters.
  - Next step: add a short end-to-end modelling example that links the susceptibility ranking output into `make_modelling_panel()` / `fit_outbreak_models()` (still using shipped example data).
- Confirm optional dependencies and gating are clearly documented.
