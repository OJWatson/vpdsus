```pm-status
milestone: M8
state: running
headSha: local-working-tree
ciRunUrl: local
updatedAtUtc: 2026-02-18T00:00:00Z
```

Note: local checks on 2026-02-18 (UTC):
- `devtools::test()` PASS (354 pass, 0 fail, 7 opt-in skips)
- `R CMD check --no-manual` PASS (Status: OK)
- `R CMD build` + `R CMD check --no-manual` with vignettes built PASS (Status: OK)

## Next steps (M8)

- Produce one end-to-end first-project report in `analysis/reports/` with live-data provenance.
- Add a single long-form "first project" tutorial that links data -> susceptibility -> modelling -> interpretation.
- Re-run `R CMD check --as-cran` and refresh CRAN-readiness notes after any remaining tutorial/report additions.
