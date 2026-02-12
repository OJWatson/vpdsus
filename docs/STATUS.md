```pm-status
milestone: M7
state: running
headSha: b38aef3404e736d90eb421622f3f15398b171e0f
ciRunUrl: https://github.com/OJWatson/vpdsus/actions/runs/21934156532, https://github.com/OJWatson/vpdsus/actions/runs/21934156528, https://github.com/OJWatson/vpdsus/actions/runs/21934156526, https://github.com/OJWatson/vpdsus/actions/runs/21934187306
updatedAtUtc: 2026-02-12T05:26:52Z
```

Note: earlier green gate for a prior head was R-CMD-check https://github.com/OJWatson/vpdsus/actions/runs/21916538155.

Note: current git HEAD is a docs-only STATUS update commit; `headSha` above tracks the last non-doc change.

## Next steps (M7)

- Local as-cran check: run `R CMD check --as-cran` with Suggests not forced; address any new NOTES/WARNINGS.
  - Remaining expected NOTES: `Remotes` field + non-CRAN Suggests; "unable to verify current time" can occur in sandboxed environments.
- Verify pkgdown/site deploy is stable (builds into `site/`; `docs/` is reserved for markdown).
- Expand vignettes to teach the workflow end-to-end (data access → susceptibility → ranking → modelling), including key columns/parameters.
  - Next: explain risk ranking parameters (`window_years`, `year_end`) and risk category semantics.
- Confirm optional dependencies and gating are clearly documented.
