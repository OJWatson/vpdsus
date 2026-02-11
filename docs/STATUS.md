```pm-status
milestone: M7
state: running
headSha: 048e62f430d4e663ae1ca8354de355d132463086
ciRunUrl: https://github.com/OJWatson/vpdsus/actions/runs/21917245472, https://github.com/OJWatson/vpdsus/actions/runs/21917245515, https://github.com/OJWatson/vpdsus/actions/runs/21917245447
updatedAtUtc: 2026-02-11T18:15:40Z
```

Note: earlier green gate for a prior head was R-CMD-check https://github.com/OJWatson/vpdsus/actions/runs/21916538155.

## Next steps (M7)

- Run a full local R CMD check (as-cran) with Suggests not forced; address any new NOTES/WARNINGS.
- Verify the pkgdown site builds cleanly and that the reference index remains consistent.
- Review README for user-facing installation, minimum supported scope, and reproducibility path.
- Confirm optional dependencies and gating are clearly documented.
- Push small commits and keep CI green; update this file after each green gate.
