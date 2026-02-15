#!/usr/bin/env bash
set -euo pipefail

# Best-effort offline vignette build.
# If user namespaces/network namespaces are available, run vignette build with networking disabled.

run_build() {
  # Use base R tooling (no devtools dependency) and avoid writing into the
  # working tree (e.g. inst/doc). We trigger vignette building via R CMD build,
  # then discard the tarball.
  rm -f vpdsus_*.tar.gz
  R CMD build . --no-manual
  rm -f vpdsus_*.tar.gz
}

if command -v unshare >/dev/null 2>&1; then
  if unshare -n true >/dev/null 2>&1; then
    echo "[offline] building vignettes with networking disabled (unshare -n)"
    unshare -n bash -lc "$(declare -f run_build); run_build"
    exit 0
  fi
fi

echo "[offline] WARNING: could not disable networking (unshare -n unavailable)."
echo "[offline] Proceeding with a standard vignette build; vignettes should not require network access."
run_build
