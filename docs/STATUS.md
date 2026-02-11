```pm-status
milestone: M7
state: waiting-for-ci
headSha: 162f9c2b19a607a35669915f82a961e2d76171dd
ciRunUrl: https://github.com/OJWatson/vpdsus/actions/runs/21916954241, https://github.com/OJWatson/vpdsus/actions/runs/21916954277, https://github.com/OJWatson/vpdsus/actions/runs/21916954307
updatedAtUtc: 2026-02-11T18:08:11Z
```

Note: earlier green gate for a prior head was R-CMD-check https://github.com/OJWatson/vpdsus/actions/runs/21916538155.

## Next steps (M7)

- Run a full local R CMD check (as-cran) with Suggests not forced; address any new NOTES/WARNINGS.
- Verify the pkgdown site builds cleanly and that the reference index remains consistent.
- Review README for user-facing installation, minimum supported scope, and reproducibility path.
- Confirm optional dependencies and gating are clearly documented.
- Push small commits and keep CI green; update this file after each green gate.
