test_that("discrete balance odin2 supports time-varying inputs (opt-in)", {
  testthat::skip_if_not_installed("odin2")
  testthat::skip_if_not_installed("dust2")

  testthat::skip_if_not(
    identical(Sys.getenv("VPDSUS_BUILD_ODIN2_VIGNETTE"), "1"),
    "Set VPDSUS_BUILD_ODIN2_VIGNETTE=1 to run odin2 mechanistic checks"
  )

  mdl <- vpdsus::odin2_build_model("balance_discrete")

  times <- 0:4
  births <- c(0, 1, 0, 0, 0)
  cases <- c(0, 0, 1, 0, 2)

  out <- vpdsus::odin2_simulate(
    mdl,
    times = times,
    pars = list(rho = 1),
    initial = list(S = 3),
    inputs = list(births = births, vaccinated = 0, cases = cases)
  )

  # Hand calculation:
  # S0=3
  # t1: +births1(=1) -> 4
  # t2: -cases2(=1) -> 3
  # t3: +0 -> 3
  # t4: -cases4(=2) -> 1
  expect_equal(out$S, c(3, 4, 3, 3, 1))

  # Named-vector convenience (times as names)
  births_named <- stats::setNames(births, as.character(times))
  cases_named <- stats::setNames(cases, as.character(times))
  out2 <- vpdsus::odin2_simulate(
    mdl,
    times = times,
    pars = list(rho = 1),
    initial = list(S = 3),
    inputs = list(births = births_named, vaccinated = 0, cases = cases_named)
  )
  expect_equal(out2$S, out$S)
})
