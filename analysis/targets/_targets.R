library(targets)

tar_option_set(
  packages = c("vpdsus", "dplyr", "ggplot2")
)

list(
  tar_target(
    panel,
    vpdsus::vpdsus_example_panel()
  ),
  tar_target(
    susc_static,
    vpdsus::estimate_susceptible_static(panel, coverage_col = "coverage", pop_col = "pop_0_4")
  ),
  tar_target(
    rank_tbl,
    vpdsus::risk_rank(panel, susc_static, window_years = 3, year_end = max(panel$year))
  ),
  tar_target(
    coverage_plot,
    vpdsus::plot_coverage_rank(rank_tbl, top_n = 10)
  ),
  tar_target(
    susceptible_plot,
    vpdsus::plot_susceptible_rank(rank_tbl, top_n = 10)
  )
)
