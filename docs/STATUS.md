```pm-status
milestone: M7
state: waiting-for-ci
headSha: be2a997dcb8c6949d345513cc7ef30851d89cf6d
ciRunUrl: https://github.com/OJWatson/vpdsus/actions/runs/21916626744, https://github.com/OJWatson/vpdsus/actions/runs/21916626729
updatedAtUtc: 2026-02-11T17:56:00Z
```

## Next steps (M7)

- Run a full local R CMD check (as-cran) with Suggests not forced; address any new NOTES/WARNINGS.
- Verify the pkgdown site builds cleanly and that the reference index remains consistent.
- Review README for user-facing installation, minimum supported scope, and reproducibility path.
- Confirm optional dependencies and gating are clearly documented.
- Push small commits and keep CI green; update this file after each green gate.
