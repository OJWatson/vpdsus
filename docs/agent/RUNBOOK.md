# Runbook

## Acceptance checks

Run from the repository root.

1) Package checks (without manual):

```sh
R CMD build .
R CMD check --no-manual vpdsus_*.tar.gz
```

2) Build pkgdown site:

```sh
Rscript -e 'pkgdown::build_site()'
```

3) Build vignettes in an offline-friendly mode (best-effort):

```sh
./scripts/build_vignettes_offline.sh
```

Notes:
- Vignettes must not depend on live data downloads.
- Live data acquisition belongs in `analysis/`.
