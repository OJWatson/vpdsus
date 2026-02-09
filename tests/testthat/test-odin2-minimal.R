test_that("minimal discrete-time odin2 model compiles and runs (opt-in)", {
  testthat::skip_if_not_installed("odin2")

  testthat::skip_if_not(
    identical(Sys.getenv("VPDSUS_BUILD_ODIN2_VIGNETTE"), "1"),
    "Set VPDSUS_BUILD_ODIN2_VIGNETTE=1 to run odin2 mechanistic checks"
  )

  mdl <- vpdsus::odin2_build_model("minimal_discrete")
  out <- vpdsus::odin2_simulate(
    mdl,
    times = 0:5,
    pars = list(inc = 1),
    initial = list(S = 0)
  )

  expect_named(out, c("time", "S"))
  expect_equal(out$time, 0:5)
  expect_equal(out$S, 0:5)
})
