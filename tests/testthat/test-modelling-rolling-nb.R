test_that("fit_outbreak_models includes NB components", {
  panel <- vpdsus_example_panel()
  suscept <- estimate_susceptible_static(panel, coverage_col = "coverage", pop_col = "pop_0_4")
  mod <- make_modelling_panel(panel, suscept, outcome = "outbreak_pc", lag_years = 1)

  fit <- fit_outbreak_models(mod)
  expect_true(all(c("model", "coefficients", "model_nb", "coefficients_nb") %in% names(fit)))
  expect_s3_class(fit$model, "glm")
  expect_s3_class(fit$coefficients_nb, "tbl_df")
})

test_that("evaluate_models_rolling_origin returns multiple splits", {
  panel <- vpdsus_example_panel()
  suscept <- estimate_susceptible_static(panel, coverage_col = "coverage", pop_col = "pop_0_4")
  mod <- make_modelling_panel(panel, suscept, outcome = "outbreak_pc", lag_years = 1)

  ev <- evaluate_models_rolling_origin(mod, min_train_years = 1)
  expect_s3_class(ev, "tbl_df")
  expect_true(all(c("train_end", "accuracy", "brier", "log_loss", "auc", "split_type") %in% names(ev)))
  expect_true(nrow(ev) >= 1)
})
