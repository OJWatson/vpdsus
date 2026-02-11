```pm-status
milestone: M7
state: waiting-for-ci
headSha: 42ba738c9ebb710a5042f63bb0d465cc4dc3e99e
ciRunUrl: https://github.com/OJWatson/vpdsus/actions/runs/21924111055, https://github.com/OJWatson/vpdsus/actions/runs/21924111045, https://github.com/OJWatson/vpdsus/actions/runs/21924111059
updatedAtUtc: 2026-02-11T21:40:44Z
```

Note: earlier green gate for a prior head was R-CMD-check https://github.com/OJWatson/vpdsus/actions/runs/21916538155.

Note: current git HEAD is a docs-only STATUS update commit; `headSha` above tracks the last non-doc change.

## Next steps (M7)

- Local as-cran check: run `R CMD check --as-cran` with Suggests not forced; address any new NOTES/WARNINGS.
  - Remaining expected NOTES: `Remotes` field + non-CRAN Suggests; "unable to verify current time" can occur in sandboxed environments.
- Verify pkgdown/site deploy is stable (builds into `site/`; `docs/` is reserved for markdown).
- Expand vignettes to teach the workflow end-to-end (data access → susceptibility → ranking → modelling), including key columns/parameters.
- Confirm optional dependencies and gating are clearly documented.
