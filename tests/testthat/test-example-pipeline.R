test_that("example pipeline runs", {
  panel <- vpdsus_example_panel()

  sA <- estimate_susceptible_static(panel, coverage_col = "coverage", pop_col = "pop_0_4")
  expect_true(all(c("susceptible_n", "susceptible_prop") %in% names(sA)))

  sB <- estimate_susceptible_cohort(panel, coverage_col = "coverage", births_col = "births", pop_col = "pop_0_4")
  expect_true(nrow(sB) == nrow(panel))

  rank <- risk_rank(panel, sA, window_years = 3, year_end = 2020)
  expect_true("risk_category" %in% names(rank))

  p1 <- plot_coverage_rank(rank, top_n = 3)
  p2 <- plot_susceptible_rank(rank, top_n = 3)
  expect_s3_class(p1, "ggplot")
  expect_s3_class(p2, "ggplot")

  mod <- make_modelling_panel(panel, sA, outcome = "outbreak_pc", lag_years = 1)
  fit <- fit_outbreak_models(mod)
  ev <- evaluate_models(mod)
  expect_true(is.list(fit))
  expect_true("accuracy" %in% names(ev))
})
