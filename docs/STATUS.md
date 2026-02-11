```pm-status
milestone: M7
state: running
headSha: dd8ac8792362700bb53dc44d9db0ead94568e55c
ciRunUrl: https://github.com/OJWatson/vpdsus/actions/runs/21921822646, https://github.com/OJWatson/vpdsus/actions/runs/21921822632, https://github.com/OJWatson/vpdsus/actions/runs/21921822654, https://github.com/OJWatson/vpdsus/actions/runs/21921883989
updatedAtUtc: 2026-02-11T20:37:38Z
```

Note: earlier green gate for a prior head was R-CMD-check https://github.com/OJWatson/vpdsus/actions/runs/21916538155.

Note: current git HEAD is a docs-only STATUS update commit; `headSha` above tracks the last non-doc change.

## Next steps (M7)

- Run a full local R CMD check (as-cran) with Suggests not forced; address any new NOTES/WARNINGS.
- Verify pkgdown/site deploy is stable (builds into `site/`; `docs/` is reserved for markdown).
- Review README for user-facing installation, minimum supported scope, and reproducibility path.
- Confirm optional dependencies and gating are clearly documented.
