#' Calibrate rho for the case-balance susceptible recurrence
#'
#' Calibrate the reporting fraction `rho` in the susceptible balance recurrence
#' used by [estimate_susceptible_case_balance()] so that the model matches a
#' target susceptible count at a chosen time.
#'
#' This helper does not require `{odin2}`.
#'
#' @param panel Panel data.frame/tibble containing at least iso3/year/births,
#'   coverage, and cases columns.
#' @param iso3 ISO3 code to filter panel.
#' @param years Vector of years (integers) to use for the recurrence. Must be
#'   covered by `panel` for `iso3`.
#' @param target_year Year at which to match `target_susceptible_n`.
#' @param target_susceptible_n Target susceptible count at `target_year`.
#' @param births_col Births column.
#' @param coverage_col Coverage column.
#' @param cases_col Cases column.
#' @param s0 Initial susceptible count at first year; defaults to births in the
#'   first year.
#' @param ve Vaccine effectiveness multiplier applied to coverage when computing
#'   vaccinated births.
#' @param rho_interval Search interval for rho.
#'
#' @return A scalar numeric rho.
#'
#' @examples
#' panel <- data.frame(
#'   iso3 = rep("AAA", 4),
#'   year = 2000:2003,
#'   births = 0,
#'   coverage = 0,
#'   cases = 10
#' )
#'
#' # With s0=100, cases=10, rho=0.5 implies depletion per step = 10/0.5=20:
#' # S: 100, 80, 60, 40
#' calibrate_rho_case_balance(
#'   panel,
#'   iso3 = "AAA",
#'   years = 2000:2003,
#'   target_year = 2003,
#'   target_susceptible_n = 40,
#'   s0 = 100,
#'   rho_interval = c(0.1, 1)
#' )
#'
#' @export
calibrate_rho_case_balance <- function(
    panel,
    iso3,
    years,
    target_year,
    target_susceptible_n,
    births_col = "births",
    coverage_col = "coverage",
    cases_col = "cases",
    s0 = NULL,
    ve = 1,
    rho_interval = c(1e-4, 1)) {
  assert_is_scalar_chr(iso3)
  rho_interval <- as.numeric(rho_interval)
  if (length(rho_interval) != 2 || anyNA(rho_interval) || rho_interval[[1]] <= 0 ||
      rho_interval[[2]] <= rho_interval[[1]]) {
    cli::cli_abort(
      "{.arg rho_interval} must be a numeric length-2 vector with 0 < lower < upper"
    )
  }
  if (!is.data.frame(panel)) {
    cli::cli_abort("{.arg panel} must be a data.frame")
  }
  years <- as.integer(years)
  target_year <- as.integer(target_year)
  target_susceptible_n <- as.numeric(target_susceptible_n)

  assert_has_cols(panel, c("iso3", "year", births_col, coverage_col, cases_col))

  df <- tibble::as_tibble(panel) |>
    dplyr::mutate(
      iso3 = standardise_iso3(.data$iso3),
      year = as.integer(.data$year),
      births = as.numeric(.data[[births_col]]),
      cov = pmin(pmax(as.numeric(.data[[coverage_col]]), 0), 1),
      cases = pmax(as.numeric(.data[[cases_col]]), 0),
      vaccinated = as.numeric(.data[[births_col]]) * cov * ve
    ) |>
    dplyr::filter(.data$iso3 == standardise_iso3(iso3), .data$year %in% years) |>
    dplyr::arrange(.data$year)

  if (!all(years %in% df$year)) {
    missing <- setdiff(years, df$year)
    cli::cli_abort("panel does not cover requested years for {iso3}: {missing}")
  }
  if (!target_year %in% df$year) {
    cli::cli_abort("{.arg target_year} must be within {.arg years}")
  }

  # index of target year in the sorted df
  idx_target <- match(target_year, df$year)

  s0_use <- if (is.null(s0)) df$births[[1]] else as.numeric(s0)

  # If there are no cases, rho is not identifiable: the recurrence does not
  # depend on rho. Return the lower bound with a warning.
  if (all(df$cases == 0)) {
    cli::cli_warn("All cases are zero: {.arg rho} is not identifiable; returning rho_interval lower bound")
    return(rho_interval[[1]])
  }

  # Define function of rho: S(target_year) - target
  f <- function(rho) {
    rho <- as.numeric(rho)
    n <- nrow(df)
    S <- numeric(n)
    S[[1]] <- s0_use
    if (n > 1) {
      for (i in 1:(n - 1)) {
        inf_i <- df$cases[[i]] / rho
        S[[i + 1]] <- max(0, S[[i]] + df$births[[i]] - df$vaccinated[[i]] - inf_i)
      }
    }
    S[[idx_target]] - target_susceptible_n
  }

  a <- rho_interval[[1]]
  b <- rho_interval[[2]]
  fa <- f(a)
  fb <- f(b)

  if (is.na(fa) || is.na(fb)) {
    cli::cli_abort("rho calibration function returned NA at interval endpoints")
  }
  if (fa == 0) return(a)
  if (fb == 0) return(b)
  if (fa * fb > 0) {
    cli::cli_abort(
      "Target not bracketed on rho_interval. f({a})={signif(fa,3)}, f({b})={signif(fb,3)}"
    )
  }

  stats::uniroot(f, lower = a, upper = b)$root
}
