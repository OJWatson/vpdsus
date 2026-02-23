test_that("sirv annual odin2 model compiles and runs (opt-in)", {
  testthat::skip_if_not_installed("odin2")
  testthat::skip_if_not_installed("dust2")

    mdl <- vpdsus::odin2_build_model("sirv_annual")
  out <- vpdsus::odin2_simulate(
    mdl,
    times = 0:5,
    pars = list(
      beta = 0.6,
      gamma = 0.2,
      mu = 0.01,
      rho = 0.5,
      births = 10,
      vaccinated = 5,
      n_pop = 1000
    ),
    initial = list(S = 900, I = 50, R = 40, V = 10)
  )

  expect_true(all(c("time", "S", "I", "R", "V", "reported_cases", "susceptible_n", "susceptible_prop") %in% names(out)))
  expect_equal(nrow(out), 6)
  expect_true(all(out$susceptible_prop >= 0))
})
