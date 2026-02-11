```pm-status
milestone: M7
state: waiting-for-ci
headSha: 5b4725fe68defb8f4af0c89dddbebd754459b04f
ciRunUrl: https://github.com/OJWatson/vpdsus/actions/runs/21924495400, https://github.com/OJWatson/vpdsus/actions/runs/21924495408, https://github.com/OJWatson/vpdsus/actions/runs/21924495385
updatedAtUtc: 2026-02-11T21:53:19Z
```

Note: earlier green gate for a prior head was R-CMD-check https://github.com/OJWatson/vpdsus/actions/runs/21916538155.

Note: current git HEAD is a docs-only STATUS update commit; `headSha` above tracks the last non-doc change.

## Next steps (M7)

- Local as-cran check: run `R CMD check --as-cran` with Suggests not forced; address any new NOTES/WARNINGS.
  - Remaining expected NOTES: `Remotes` field + non-CRAN Suggests; "unable to verify current time" can occur in sandboxed environments.
- Verify pkgdown/site deploy is stable (builds into `site/`; `docs/` is reserved for markdown).
- Expand vignettes to teach the workflow end-to-end (data access → susceptibility → ranking → modelling), including key columns/parameters.
- Confirm optional dependencies and gating are clearly documented.
