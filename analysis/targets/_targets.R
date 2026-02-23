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
  ),
  tar_target(
    analysis_outputs,
    {
      out_dir <- file.path("analysis", "outputs", "example")
      dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

      rank_path <- file.path(out_dir, "rank_table.csv")
      coverage_path <- file.path(out_dir, "coverage_rank_top10.png")
      susceptible_path <- file.path(out_dir, "susceptible_rank_top10.png")
      metadata_path <- file.path(out_dir, "run_metadata.txt")

      utils::write.csv(rank_tbl, rank_path, row.names = FALSE)
      ggplot2::ggsave(coverage_path, plot = coverage_plot, width = 9, height = 5, dpi = 150)
      ggplot2::ggsave(susceptible_path, plot = susceptible_plot, width = 9, height = 5, dpi = 150)

      metadata <- c(
        paste0("vpdsus_version=", as.character(utils::packageVersion("vpdsus"))),
        paste0("n_rows_rank_table=", nrow(rank_tbl)),
        paste0("year_range=", min(panel$year), "-", max(panel$year)),
        paste0("iso3_count=", dplyr::n_distinct(panel$iso3))
      )
      writeLines(metadata, metadata_path)

      c(rank_path, coverage_path, susceptible_path, metadata_path)
    },
    format = "file"
  )
)
