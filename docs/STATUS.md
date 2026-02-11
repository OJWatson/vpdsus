```pm-status
milestone: M7
state: waiting-for-ci
headSha: 28a0fe33339577cad94766cf36548f98eff183d2
ciRunUrl: https://github.com/OJWatson/vpdsus/actions/runs/21916834356, https://github.com/OJWatson/vpdsus/actions/runs/21916834366, https://github.com/OJWatson/vpdsus/actions/runs/21916834355
updatedAtUtc: 2026-02-11T18:01:31Z
```

Note: earlier green gate for a prior head was R-CMD-check https://github.com/OJWatson/vpdsus/actions/runs/21916538155.

## Next steps (M7)

- Run a full local R CMD check (as-cran) with Suggests not forced; address any new NOTES/WARNINGS.
- Verify the pkgdown site builds cleanly and that the reference index remains consistent.
- Review README for user-facing installation, minimum supported scope, and reproducibility path.
- Confirm optional dependencies and gating are clearly documented.
- Push small commits and keep CI green; update this file after each green gate.
