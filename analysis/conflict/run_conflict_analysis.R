#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(vpdsus)
  library(dplyr)
  library(ggplot2)
})

out_dir <- "analysis/outputs/conflict"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

panel <- vpdsus_example_panel()
conf <- get_conflict(
  years = sort(unique(panel$year)),
  countries = unique(panel$iso3),
  source = "ucdp_fixture"
)
panel_conf <- merge_conflict_with_panel(panel, conf)

# Include susceptibility so outbreak context can still be compared.
sus <- estimate_susceptible_static(panel_conf, coverage_col = "coverage", pop_col = "pop_0_4")
mod_base <- make_modelling_panel(panel_conf, sus, outcome = "outbreak_pc", lag_years = 1)
mod_conf <- make_conflict_modelling_panel(panel_conf, lag_years = 1, outcome = "outbreak_pc")
fit_conf <- fit_conflict_effect_models(mod_conf)

# Summaries
summ <- panel_conf |>
  summarise(
    n_rows = n(),
    n_countries = n_distinct(iso3),
    year_min = min(year, na.rm = TRUE),
    year_max = max(year, na.rm = TRUE),
    conflict_share = mean(conflict_any_event, na.rm = TRUE),
    mean_conflict_fatalities_per_100k = mean(conflict_fatalities_per_100k, na.rm = TRUE)
  )

write.csv(summ, file.path(out_dir, "conflict_summary.csv"), row.names = FALSE)
write.csv(fit_conf$coefficients, file.path(out_dir, "conflict_model_coefficients.csv"), row.names = FALSE)
write.csv(mod_conf, file.path(out_dir, "conflict_modelling_panel.csv"), row.names = FALSE)
write.csv(mod_base, file.path(out_dir, "baseline_modelling_panel.csv"), row.names = FALSE)

# Plot: conflict exposure over time
plt_conf <- panel_conf |>
  filter(conflict_data_available) |>
  group_by(year) |>
  summarise(
    any_conflict_share = mean(conflict_any_event, na.rm = TRUE),
    mean_fatalities_per_100k = mean(conflict_fatalities_per_100k, na.rm = TRUE),
    .groups = "drop"
  )

g <- ggplot(plt_conf, aes(x = year, y = any_conflict_share)) +
  geom_line(linewidth = 0.8, colour = "#B22222") +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  labs(
    x = "Year",
    y = "Share of countries with conflict",
    title = "Conflict occurrence over time"
  ) +
  theme_minimal(base_size = 11)

ggsave(file.path(out_dir, "plot_conflict_occurrence_over_time.png"), g, width = 9, height = 5, dpi = 150)

cat("Conflict analysis complete. Outputs in", out_dir, "\n")
