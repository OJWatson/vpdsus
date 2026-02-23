script <- "analysis/targets/_targets.R"

if (!requireNamespace("targets", quietly = TRUE)) {
  stop("Package 'targets' is required. Install it with install.packages('targets').", call. = FALSE)
}

targets::tar_config_set(script = script, store = "analysis/targets/_targets_store")
targets::tar_destroy(destroy = "process")
targets::tar_make()

out <- targets::tar_read(analysis_outputs)
cat("analysis outputs:\n")
cat(paste0(" - ", out), sep = "\n")
