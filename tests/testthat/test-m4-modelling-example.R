test_that("M4 slice: modelling panel + baseline model fit + evaluation runs on example data", {
  panel <- vpdsus_example_panel()
  suscept <- estimate_susceptible_static(panel, coverage_col = "coverage", pop_col = "pop_0_4")

  data <- make_modelling_panel(panel, suscept, outcome = "outbreak_pc", lag_years = 1)
  expect_true(is.data.frame(data))
  expect_true(all(c("iso3", "year", "year_next", "outcome", "susceptible_prop", "cases_next", "who_region") %in% names(data)))
  expect_true(nrow(data) > 0)

  fit <- fit_outbreak_models(data)
  expect_true(is.list(fit))
  expect_s3_class(fit$model, "glm")
  expect_true(is.data.frame(fit$coefficients))
  expect_true(any(fit$coefficients$term == "susceptible_prop"))
  expect_true(is.finite(stats::AIC(fit$model)))

  ev <- evaluate_models(data)
  expect_true(is.data.frame(ev))
  expect_true(all(c("train_end", "n_train", "n_test", "accuracy", "brier") %in% names(ev)))
  expect_true(ev$n_train >= 1)
})
