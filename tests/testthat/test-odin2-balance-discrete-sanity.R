test_that("odin2 balance_discrete sanity: depletion monotonic when births=vaccinated=0", {
  if (Sys.getenv("VPDSUS_BUILD_ODIN2_VIGNETTE") != "1") {
    skip("Set VPDSUS_BUILD_ODIN2_VIGNETTE=1 to run odin2 mechanistic checks")
  }
  skip_if_not_installed("odin2")
  skip_if_not_installed("dust2")

  mdl <- odin2_build_model("balance_discrete")

  times <- 0:5
  out <- odin2_simulate(
    mdl,
    times = times,
    pars = list(rho = 1),
    initial = list(S = 10),
    inputs = list(
      births = 0,
      vaccinated = 0,
      cases = c(0, 1, 0, 2, 0, 0)
    )
  )

  expect_true(is.data.frame(out))
  expect_true(all(c("time", "S") %in% names(out)))
  expect_equal(nrow(out), length(times))

  # With births=vaccinated=0 and non-negative cases, S should be non-increasing
  expect_true(all(diff(out$S) <= 1e-8))
})
