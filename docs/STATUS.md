```pm-status
milestone: M7
state: running
headSha: 73013ccdfbb358ceebbbfcc1665f4c4f157005ab
ciRunUrl: https://github.com/OJWatson/vpdsus/actions/runs/21936959652, https://github.com/OJWatson/vpdsus/actions/runs/21936959658, https://github.com/OJWatson/vpdsus/actions/runs/21936959654
updatedAtUtc: 2026-02-12T07:44:00Z
```

Note: earlier green gate for a prior head was R-CMD-check https://github.com/OJWatson/vpdsus/actions/runs/21916538155.

Note: current git HEAD may include docs-only commits; `headSha` above tracks the last non-doc change.

## Next steps (M7)

- (Done) Local as-cran check: ran `R CMD check --as-cran` with Suggests not forced.
  - Remaining expected NOTES: `Remotes` field + non-CRAN Suggests; "unable to verify current time" can occur in sandboxed environments.
- (Done) Verify pkgdown/site deploy is stable (builds into `site/`; `docs/` is reserved for markdown).
  - Verified locally via `pkgdown::build_site(override = list(destination = "site"), preview = FALSE)`.
- (Done) Expand vignettes to teach the workflow end-to-end (data access → susceptibility → ranking → modelling), including key columns/parameters.
  - Added a short end-to-end modelling example linking the susceptibility estimate into `make_modelling_panel()` / `fit_outbreak_models()` and showing how to inspect predicted probabilities.
- Next step: confirm optional dependencies and gating are clearly documented (incl. suggests not forced + opt-in odin2/inference hooks).
