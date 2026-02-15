test_that("M4.1: evaluation metrics are stable on example data for a fixed split", {
  panel <- vpdsus_example_panel()
  suscept <- estimate_susceptible_static(panel, coverage_col = "coverage", pop_col = "pop_0_4")
  mod <- make_modelling_panel(panel, suscept, outcome = "outbreak_pc", lag_years = 1)

  # Use a fixed cutoff for determinism (avoid depending on year-count heuristic).
  train_end <- sort(unique(mod$year))[length(unique(mod$year)) - 1]

  ev <- evaluate_outbreak_time_split(mod, train_end = train_end)

  expect_s3_class(ev$metrics, "tbl_df")
  expect_true(all(c("train_end", "n_train", "n_test", "accuracy", "brier", "log_loss", "auc") %in% names(ev$metrics)))
  expect_true(nrow(ev$predictions) > 0)

  metrics_print <- capture.output(print(dplyr::mutate(ev$metrics, dplyr::across(where(is.numeric), ~ round(.x, 6)))))
  expect_snapshot_output(metrics_print)
})
