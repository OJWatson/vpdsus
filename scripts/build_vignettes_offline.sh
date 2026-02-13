#!/usr/bin/env bash
set -euo pipefail

# Best-effort offline vignette build.
# If user namespaces/network namespaces are available, run vignette build with networking disabled.

run_build() {
  Rscript -e 'devtools::build_vignettes()'
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
