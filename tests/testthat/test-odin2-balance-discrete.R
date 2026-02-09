test_that("discrete balance odin2 model invariants (opt-in)", {
  testthat::skip_if_not_installed("odin2")
  testthat::skip_if_not_installed("dust2")

  testthat::skip_if_not(
    identical(Sys.getenv("VPDSUS_BUILD_ODIN2_VIGNETTE"), "1"),
    "Set VPDSUS_BUILD_ODIN2_VIGNETTE=1 to run odin2 mechanistic checks"
  )

  mdl <- vpdsus::odin2_build_model("balance_discrete")

  # 1) No flows -> constant
  out0 <- vpdsus::odin2_simulate(
    mdl,
    times = 0:5,
    pars = list(rho = 1, births = 0, vaccinated = 0, cases = 0),
    initial = list(S = 10)
  )
  expect_equal(out0$S, rep(10, 6))

  # 2) Cases reduce S (with rho=1) and floor at 0
  out1 <- vpdsus::odin2_simulate(
    mdl,
    times = 0:5,
    pars = list(rho = 1, births = 0, vaccinated = 0, cases = 1),
    initial = list(S = 3)
  )
  expect_true(all(out1$S >= 0))
  expect_equal(out1$S, c(3, 2, 1, 0, 0, 0))
})
