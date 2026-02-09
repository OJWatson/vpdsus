test_that("calibrate_rho_case_balance recovers rho on synthetic data", {
  # Construct a simple panel with constant births, no vaccination, constant cases
  # so the recurrence is easy to reason about.
  panel <- tibble::tibble(
    iso3 = rep("AAA", 4),
    year = 2000:2003,
    births = 0,
    coverage = 0,
    cases = 10
  )

  # With s0=100, births=0, vaccinated=0, cases=10, rho=0.5
  # depletion per step is 10 / 0.5 = 20.
  # S: 100, 80, 60, 40.
  rho_true <- 0.5

  rho_hat <- calibrate_rho_case_balance(
    panel,
    iso3 = "AAA",
    years = 2000:2003,
    target_year = 2003,
    target_susceptible_n = 40,
    s0 = 100,
    rho_interval = c(0.1, 1)
  )

  expect_equal(rho_hat, rho_true, tolerance = 1e-4)
})

test_that("calibrate_rho_case_balance errors if target not bracketed", {
  panel <- tibble::tibble(
    iso3 = rep("AAA", 2),
    year = 2000:2001,
    births = 0,
    coverage = 0,
    cases = 10
  )

  expect_error(
    calibrate_rho_case_balance(
      panel,
      iso3 = "AAA",
      years = 2000:2001,
      target_year = 2001,
      target_susceptible_n = 999,
      s0 = 100,
      rho_interval = c(0.1, 1)
    ),
    "Target not bracketed"
  )
})
