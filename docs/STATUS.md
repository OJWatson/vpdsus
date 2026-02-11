```pm-status
milestone: M7
state: waiting-for-ci
headSha: 88a335861d6d5de453038e82fc265e0d60859419
ciRunUrl: https://github.com/OJWatson/vpdsus/actions/runs/21916538155, https://github.com/OJWatson/vpdsus/actions/runs/21916538194
updatedAtUtc: 2026-02-11T17:55:18Z
```

## Next steps (M7)

- Run a full local R CMD check (as-cran) with Suggests not forced; address any new NOTES/WARNINGS.
- Verify the pkgdown site builds cleanly and that the reference index remains consistent.
- Review README for user-facing installation, minimum supported scope, and reproducibility path.
- Confirm optional dependencies and gating are clearly documented.
- Push small commits and keep CI green; update this file after each green gate.
