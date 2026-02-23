#!/usr/bin/env Rscript

if (!requireNamespace("odin2", quietly = TRUE)) {
  stop("Package 'odin2' is required.", call. = FALSE)
}

odin2::odin_package(".")
cat("Updated odin2 generated files in inst/dust/, src/, and R/dust.R\n")
