#' Build odin2 input vectors from a year-keyed tibble
#'
#' Convenience helper for preparing `inputs=` for [odin2_simulate()].
#'
#' @param data A data frame/tibble containing a time column (default `year`) and
#'   one or more input columns (e.g. `births`, `vaccinated`, `cases`).
#' @param times Numeric/integer vector of times (typically years) to align to.
#' @param cols Character vector of input column names to extract.
#' @param time_col Name of the time column in `data`.
#' @param iso3 Optional ISO3 code to filter `data` when it contains multiple
#'   countries.
#' @param iso3_col Name of the ISO3 column in `data`.
#'
#' @return Named list of numeric vectors, each of length `length(times)`.
#' @export
odin2_inputs_from_tibble <- function(
    data,
    times,
    cols = c("births", "vaccinated", "cases"),
    time_col = "year",
    iso3 = NULL,
    iso3_col = "iso3") {
  if (!is.data.frame(data)) {
    cli::cli_abort("{.arg data} must be a data.frame")
  }
  if (length(times) == 0) {
    cli::cli_abort("{.arg times} must have length > 0")
  }

  if (!time_col %in% names(data)) {
    cli::cli_abort("{.arg data} is missing time column '{time_col}'")
  }

  if (!is.null(iso3)) {
    if (!iso3_col %in% names(data)) {
      cli::cli_abort("{.arg data} is missing iso3 column '{iso3_col}'")
    }
    data <- data[data[[iso3_col]] == iso3, , drop = FALSE]
  }

  missing_cols <- setdiff(cols, names(data))
  if (length(missing_cols) > 0) {
    cli::cli_abort("{.arg data} is missing input columns: {missing_cols}")
  }

  # Keep only relevant columns and drop duplicate (time, iso3) rows if present.
  keep <- unique(c(time_col, iso3_col, cols))
  keep <- keep[keep %in% names(data)]
  data2 <- data[, keep, drop = FALSE]

  # If iso3 was not provided and iso3 exists, ensure data is single-country.
  if (is.null(iso3) && iso3_col %in% names(data2)) {
    u <- unique(stats::na.omit(data2[[iso3_col]]))
    if (length(u) > 1) {
      cli::cli_abort(
        "{.arg data} contains multiple iso3 values; pass {.arg iso3} to select one"
      )
    }
  }

  # Build mapping from times to rows.
  tchr <- as.character(times)
  data_times <- as.character(data2[[time_col]])

  missing_times <- setdiff(tchr, unique(data_times))
  if (length(missing_times) > 0) {
    cli::cli_abort(
      "{.arg data} does not cover all requested times. Missing: {missing_times}"
    )
  }

  # Select first row for each time (if duplicates exist).
  idx <- match(tchr, data_times)

  out <- purrr::map(cols, function(nm) {
    as.numeric(data2[[nm]][idx])
  })
  names(out) <- cols
  out
}
#' Build susceptible-balance inputs from a panel
#'
#' Convenience helper to construct `inputs=` for the discrete-time susceptible
#' balance odin2 model (`model = "balance_discrete"`).
#'
#' This function does **not** require `{odin2}` or `{dust2}`.
#'
#' @param panel Panel data.frame/tibble containing at least `iso3`, `year`,
#'   births, coverage, and cases columns (configurable via `*_col`).
#' @param times Numeric/integer vector of times (typically years) to align to.
#' @param iso3 ISO3 code to filter `panel`.
#' @param year_col Year column.
#' @param births_col Births column.
#' @param coverage_col Coverage column on the interval \[0, 1\]; values outside are clamped.
#'   (Coverage values are bounded to the interval \[0, 1\].)
#' @param cases_col Cases column.
#' @param ve Vaccine effectiveness multiplier applied to coverage when computing
#'   vaccinated births (`vaccinated = births * coverage * ve`).
#'
#' @return Named list with numeric vectors `births`, `vaccinated`, `cases`, each
#'   of length `length(times)`.
#' @export
odin2_balance_inputs_from_panel <- function(
    panel,
    times,
    iso3,
    year_col = "year",
    births_col = "births",
    coverage_col = "coverage",
    cases_col = "cases",
    ve = 1) {
  assert_is_scalar_chr(iso3)
  if (!is.data.frame(panel)) {
    cli::cli_abort("{.arg panel} must be a data.frame")
  }
  assert_has_cols(panel, c("iso3", year_col, births_col, coverage_col, cases_col))

  df <- tibble::as_tibble(panel) |>
    dplyr::mutate(
      iso3 = standardise_iso3(.data$iso3),
      year = as.integer(.data[[year_col]]),
      births = as.numeric(.data[[births_col]]),
      coverage = pmin(pmax(as.numeric(.data[[coverage_col]]), 0), 1),
      cases = as.numeric(.data[[cases_col]])
    ) |>
    dplyr::filter(.data$iso3 == standardise_iso3(iso3)) |>
    dplyr::transmute(
      year = .data$year,
      births = .data$births,
      vaccinated = .data$births * .data$coverage * ve,
      cases = .data$cases
    )

  odin2_inputs_from_tibble(
    df,
    times = times,
    cols = c("births", "vaccinated", "cases"),
    time_col = "year",
    iso3 = NULL
  )
}
#' Compile an odin2 template
#'
#' @param model One of 'balance', 'balance_discrete', 'sir', 'sirv_annual', or 'minimal_discrete'.
#' @param file Optional path to a custom odin file. If provided, this is
#'   compiled with [odin2::odin()] and returned directly.
#'
#' @return A compiled odin2 model object.
#' @export
odin2_build_model <- function(model = c("balance", "balance_discrete", "sir", "sirv_annual", "minimal_discrete"), file = NULL) {
  model <- match.arg(model)

  if (!is.null(file)) {
    if (!nzchar(file) || !file.exists(file)) {
      cli::cli_abort("odin template file not found: {file}")
    }
    return(odin2::odin(file))
  }

  generated_name <- switch(
    model,
    balance = "susceptible_balance",
    balance_discrete = "susceptible_balance_discrete",
    sir = "sir_basic",
    sirv_annual = "sirv_annual",
    minimal_discrete = "minimal_discrete"
  )

  if (!exists(generated_name, envir = asNamespace("vpdsus"), inherits = FALSE)) {
    cli::cli_abort(c(
      "Compiled odin system '{generated_name}' not found in package namespace.",
      "i" = "Run odin2::odin_package('.') in the package root and reinstall."
    ))
  }

  get(generated_name, envir = asNamespace("vpdsus"), inherits = FALSE)
}

#' Simulate an odin2 model
#'
#' @param model Compiled model from [odin2_build_model()].
#' @param times Numeric vector.
#' @param pars Named list.
#' @param initial Named list.
#' @param inputs Optional named list of input vectors (for difference-equation models).
#'
#' @return tibble.
#' @export
odin2_simulate <- function(model, times, pars = list(), initial = list(), inputs = NULL) {
  if (is.character(model) && length(model) == 1) {
    model <- odin2_build_model(model)
  }

  # Create a system and simulate over requested times.
  sys <- dust2::dust_system_create(model, pars = pars, time = min(times))

  # Set initial state (odin2 discrete-time systems do not allow initial() to
  # depend on parameters, so we set state explicitly here).
  if (length(initial) > 0) {
    st <- dust2::dust_system_state(sys)
    nms <- sys$packer_state$names()
    names(st) <- nms
    init_vec <- unlist(initial, use.names = TRUE)
    if (!all(names(init_vec) %in% nms)) {
      bad <- setdiff(names(init_vec), nms)
      cli::cli_abort("Unknown initial state names: {paste(bad, collapse = ', ')}")
    }
    st[names(init_vec)] <- as.numeric(init_vec)
    dust2::dust_system_set_state(sys, st)
  }

  state_names <- sys$packer_state$names()

  # Helper: extract state as a named numeric vector
  get_state <- function() {
    st <- dust2::dust_system_state(sys)
    names(st) <- state_names
    st
  }

  # No inputs -> fast path
  if (is.null(inputs)) {
    sim <- dust2::dust_system_simulate(sys, times)
    out <- tibble::tibble(time = times)
    for (i in seq_along(state_names)) {
      out[[state_names[[i]]]] <- as.numeric(sim[i, ])
    }
    return(out)
  }

  # Time-varying inputs: update parameters stepwise.
  # Inputs can be:
  #   - scalars (recycled)
  #   - vectors aligned to `times`
  #   - named vectors whose names match `times` (e.g. years)
  inputs2 <- inputs
  for (nm in names(inputs2)) {
    x <- inputs2[[nm]]
    if (length(x) == 1) {
      inputs2[[nm]] <- rep(x, length(times))
    } else if (!is.null(names(x)) && all(as.character(times) %in% names(x))) {
      inputs2[[nm]] <- as.numeric(x[as.character(times)])
    } else if (length(x) == length(times)) {
      inputs2[[nm]] <- as.numeric(x)
    } else {
      cli::cli_abort(
        "Input '{nm}' must be length 1, length(times) ({length(times)}), or a named vector covering all times"
      )
    }
  }

  out <- tibble::tibble(time = times)
  for (nm in state_names) {
    out[[nm]] <- NA_real_
  }

  # Record initial state at times[1]
  st <- get_state()
  for (nm in state_names) {
    out[[nm]][[1]] <- st[[nm]]
  }

  if (length(times) == 1) {
    return(out)
  }

  for (i in 2:length(times)) {
    pars_step <- purrr::map_dbl(inputs2, ~ .x[[i]])
    dust2::dust_system_update_pars(sys, as.list(pars_step))
    dust2::dust_system_run_to_time(sys, times[[i]])

    st <- get_state()
    for (nm in state_names) {
      out[[nm]][[i]] <- st[[nm]]
    }
  }

  out
}

#' Compare susceptibility trajectories across methods
#'
#' @param panel A panel with iso3/year.
#' @param estimates Named list of susceptibility tibbles.
#' @param iso3 Country ISO3.
#' @export
compare_methods <- function(panel, estimates, iso3) {
  assert_is_scalar_chr(iso3)
  df <- purrr::imap_dfr(estimates, function(x, nm) {
    tibble::as_tibble(x) |>
      dplyr::filter(.data$iso3 == standardise_iso3(iso3)) |>
      dplyr::mutate(method = nm)
  })

  ggplot2::ggplot(df, ggplot2::aes(x = .data$year, y = .data$susceptible_prop, colour = .data$method)) +
    ggplot2::geom_line() +
    ggplot2::scale_y_continuous(labels = scales::percent_format()) +
    ggplot2::labs(x = NULL, y = "Susceptible proportion", title = paste("Susceptibility trajectories:", iso3)) +
    vpdsus_theme()
}
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
      vaccinated = as.numeric(.data[[births_col]]) * .data$cov * ve
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
