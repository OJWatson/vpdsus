test_that("e2e: example panel -> balance_discrete odin2 simulation", {
  testthat::skip_if_not_installed("odin2")
  testthat::skip_if_not_installed("dust2")

  panel_path <- system.file("extdata", "example_panel_measles_global.csv", package = "vpdsus")
  expect_true(nzchar(panel_path))

  panel <- utils::read.csv(panel_path)

  panel_ok <- panel |>
    dplyr::filter(!is.na(iso3), !is.na(year), !is.na(births), !is.na(coverage), !is.na(cases))
  iso3 <- panel_ok$iso3[[1]]
  times <- sort(unique(panel_ok$year[panel_ok$iso3 == iso3]))

  inputs <- odin2_balance_inputs_from_panel(panel_ok, times = times, iso3 = iso3)

  mdl <- odin2_build_model("balance_discrete")

  out <- odin2_simulate(
    mdl,
    times = times,
    pars = list(rho = 1),
    initial = list(S = 0),
    inputs = inputs
  )

  expect_named(out, c("time", "S"))
  expect_equal(out$time, times)
  expect_true(all(is.finite(out$S)))
  expect_true(all(out$S >= 0))
})
