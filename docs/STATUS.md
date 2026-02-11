```pm-status
milestone: M7
state: waiting-for-ci
headSha: 8b592227d682f5827ce07e979f5a89d4fafb6d4e
ciRunUrl: https://github.com/OJWatson/vpdsus/actions/runs/21920098880, https://github.com/OJWatson/vpdsus/actions/runs/21920098892, https://github.com/OJWatson/vpdsus/actions/runs/21920098964
updatedAtUtc: 2026-02-11T19:35:18Z
```

Note: earlier green gate for a prior head was R-CMD-check https://github.com/OJWatson/vpdsus/actions/runs/21916538155.

Note: current git HEAD is a docs-only STATUS update commit; `headSha` above tracks the last non-doc change.

## Next steps (M7)

- Run a full local R CMD check (as-cran) with Suggests not forced; address any new NOTES/WARNINGS.
- Verify pkgdown/site deploy is stable (builds into `site/`; `docs/` is reserved for markdown).
- Review README for user-facing installation, minimum supported scope, and reproducibility path.
- Confirm optional dependencies and gating are clearly documented.
