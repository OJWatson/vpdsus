```pm-status
milestone: M7
state: running
headSha: 74adb359597c49efd63165c10c453c90028649a6
ciRunUrl: https://github.com/OJWatson/vpdsus/actions/runs/21916214031
updatedAtUtc: 2026-02-11T17:45:13Z
```

## Next steps (M7)

- Run a full local R CMD check (as-cran) with Suggests not forced; address any new NOTES/WARNINGS.
- Verify the pkgdown site builds cleanly and that the reference index remains consistent.
- Review README for user-facing installation, minimum supported scope, and reproducibility path.
- Confirm optional dependencies and gating are clearly documented.
- Push small commits and keep CI green; update this file after each green gate.
