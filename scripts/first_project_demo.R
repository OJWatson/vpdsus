#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(vpdsus)
  library(ggplot2)
})

out_dir <- "analysis/outputs/first_project"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

panel <- vpdsus_example_panel()

suscept <- estimate_susceptible_static(
  panel,
  coverage_col = "coverage",
  pop_col = "pop_0_4"
)

rank <- risk_rank(panel, suscept, window_years = 3, year_end = max(panel$year))

p_cov <- plot_coverage_rank(rank, top_n = 10)
p_sus <- plot_susceptible_rank(rank, top_n = 10)

mod <- make_modelling_panel(panel, suscept)
fit <- fit_outbreak_models(mod)

utils::write.csv(rank, file.path(out_dir, "rank_table.csv"), row.names = FALSE)
utils::write.csv(fit$coefficients, file.path(out_dir, "model_coefficients.csv"), row.names = FALSE)
ggsave(file.path(out_dir, "coverage_rank_top10.png"), p_cov, width = 9, height = 5, dpi = 150)
ggsave(file.path(out_dir, "susceptible_rank_top10.png"), p_sus, width = 9, height = 5, dpi = 150)

cat("First project demo complete.\n")
cat("Outputs written to:", out_dir, "\n")
cat("Fitted model objects:\n")
cat(" -", names(fit), sep = "\n")
