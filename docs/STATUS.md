```pm-status
milestone: M7
state: waiting-for-ci
headSha: 777dde9546e7dbe87282d1caf64c4e2ee5b8f878
ciRunUrl: (pending)
updatedAtUtc: 2026-02-11T18:00:49Z
```

Note: earlier green gate for a prior head was R-CMD-check https://github.com/OJWatson/vpdsus/actions/runs/21916538155.

## Next steps (M7)

- Run a full local R CMD check (as-cran) with Suggests not forced; address any new NOTES/WARNINGS.
- Verify the pkgdown site builds cleanly and that the reference index remains consistent.
- Review README for user-facing installation, minimum supported scope, and reproducibility path.
- Confirm optional dependencies and gating are clearly documented.
- Push small commits and keep CI green; update this file after each green gate.
