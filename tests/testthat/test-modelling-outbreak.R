test_that("make_modelling_panel produces expected columns and lag", {
  panel <- vpdsus_example_panel()
  suscept <- estimate_susceptible_static(panel, coverage_col = "coverage", pop_col = "pop_0_4")

  mod <- make_modelling_panel(panel, suscept, outcome = "outbreak_pc", lag_years = 1)

  expect_s3_class(mod, "tbl_df")
  expect_true(all(c(
    "iso3", "year", "year_next", "outcome",
    "susceptible_prop", "cases", "cases_next",
    "cases_per_100k", "pop_total", "who_region"
  ) %in% names(mod)))

  expect_true(all(mod$year_next == mod$year + 1L))
  expect_true(all(mod$outcome %in% c(0L, 1L)))
})

test_that("fit_outbreak_models fits a baseline logistic regression", {
  panel <- vpdsus_example_panel()
  suscept <- estimate_susceptible_static(panel, coverage_col = "coverage", pop_col = "pop_0_4")
  mod <- make_modelling_panel(panel, suscept, outcome = "outbreak_pc", lag_years = 1)

  fit <- fit_outbreak_models(mod)

  expect_true(is.list(fit))
  expect_true(all(c("model", "coefficients") %in% names(fit)))

  expect_s3_class(fit$model, "glm")
  expect_identical(fit$model$family$family, "binomial")

  coefs <- fit$coefficients
  expect_s3_class(coefs, "tbl_df")
  expect_true("susceptible_prop" %in% coefs$term)
  expect_true(all(c("term", "estimate", "std_error") %in% names(coefs)))
})
