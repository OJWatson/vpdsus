test_that("rho calibration + odin2 simulation runs end-to-end (opt-in)", {
  # This integration test requires odin2 + dust2.
  skip_if_not_installed("odin2")
  skip_if_not_installed("dust2")

  panel <- tibble::tibble(
    iso3 = rep("AAA", 4),
    year = 2000:2003,
    births = c(100, 100, 100, 100),
    coverage = c(0.5, 0.5, 0.5, 0.5),
    cases = c(10, 10, 10, 10)
  )
  iso3 <- "AAA"

  years <- panel$year
  expect_true(length(years) >= 3)

  # Build inputs for the discrete balance model
  inputs <- odin2_balance_inputs_from_panel(panel, iso3 = iso3, times = years)
  expect_true(is.list(inputs))
  expect_true(all(c("births", "vaccinated", "cases") %in% names(inputs)))

  # Construct a deterministic target from a known rho using the same recurrence
  # as calibrate_rho_case_balance().
  rho_true <- 0.5
  s0 <- 100

  df <- tibble::as_tibble(panel) |>
    dplyr::mutate(
      iso3 = standardise_iso3(.data$iso3),
      year = as.integer(.data$year),
      births = as.numeric(.data$births),
      cov = pmin(pmax(as.numeric(.data$coverage), 0), 1),
      cases = pmax(as.numeric(.data$cases), 0),
      vaccinated = births * cov
    ) |>
    dplyr::filter(.data$iso3 == standardise_iso3(iso3), .data$year %in% years) |>
    dplyr::arrange(.data$year)

  S <- numeric(nrow(df))
  S[[1]] <- s0
  for (i in 1:(nrow(df) - 1)) {
    S[[i + 1]] <- max(0, S[[i]] + df$births[[i]] - df$vaccinated[[i]] - df$cases[[i]] / rho_true)
  }

  target_year <- df$year[[nrow(df)]]
  target_susceptible_n <- S[[nrow(df)]]

  rho_hat <- calibrate_rho_case_balance(
    panel,
    iso3 = iso3,
    years = years,
    target_year = target_year,
    target_susceptible_n = target_susceptible_n,
    s0 = s0,
    rho_interval = c(0.1, 1)
  )

  expect_true(is.numeric(rho_hat) && length(rho_hat) == 1 && is.finite(rho_hat))
  expect_gte(rho_hat, 0.1)
  expect_lte(rho_hat, 1)

  # Run the mechanistic discrete balance model using the calibrated rho.
  sim <- odin2_simulate(
    model = "balance_discrete",
    times = years,
    inputs = inputs,
    pars = list(rho = rho_hat),
    initial = list(S = s0)
  )

  expect_true(is.data.frame(sim))
  expect_true(all(c("time", "S") %in% names(sim)))
  expect_equal(nrow(sim), length(years))
})
