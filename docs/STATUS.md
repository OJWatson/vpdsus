```pm-status
milestone: M7
state: waiting-for-ci
headSha: 16f3ca29bb16cc763bf80e7f47789ac2033b96ef
ciRunUrl: https://github.com/OJWatson/vpdsus/actions/runs/21916852976, https://github.com/OJWatson/vpdsus/actions/runs/21916852954, https://github.com/OJWatson/vpdsus/actions/runs/21916852979
updatedAtUtc: 2026-02-11T18:04:17Z
```

Note: earlier green gate for a prior head was R-CMD-check https://github.com/OJWatson/vpdsus/actions/runs/21916538155.

## Next steps (M7)

- Run a full local R CMD check (as-cran) with Suggests not forced; address any new NOTES/WARNINGS.
- Verify the pkgdown site builds cleanly and that the reference index remains consistent.
- Review README for user-facing installation, minimum supported scope, and reproducibility path.
- Confirm optional dependencies and gating are clearly documented.
- Push small commits and keep CI green; update this file after each green gate.
