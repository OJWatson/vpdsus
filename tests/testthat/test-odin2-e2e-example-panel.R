test_that("e2e: example panel -> balance_discrete odin2 simulation (opt-in)", {
  testthat::skip_if_not_installed("odin2")
  testthat::skip_if_not_installed("dust2")

  testthat::skip_if_not(
    identical(Sys.getenv("VPDSUS_BUILD_ODIN2_VIGNETTE"), "1"),
    "Set VPDSUS_BUILD_ODIN2_VIGNETTE=1 to run odin2 mechanistic checks"
  )

  panel_path <- system.file("extdata", "example_panel_small.csv", package = "vpdsus")
  expect_true(nzchar(panel_path))

  panel <- utils::read.csv(panel_path)

  iso3 <- panel$iso3[[1]]
  times <- sort(unique(panel$year))

  inputs <- odin2_balance_inputs_from_panel(panel, times = times, iso3 = iso3)

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
