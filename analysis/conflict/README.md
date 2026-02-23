# Conflict + vaccination/outbreak analysis (R)

This directory provides an R-native workflow to merge conflict exposure onto the
`vpdsus` country-year panel and evaluate whether conflict predicts:

- next-year outbreak occurrence,
- changes in measles cases,
- changes in vaccine coverage.

## Run

```sh
Rscript analysis/conflict/run_conflict_analysis.R
```

Outputs are written to `analysis/outputs/conflict/`.
