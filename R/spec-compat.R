# Spec-compatibility wrappers and higher-level helpers

#' Build panel directly from source accessors
#'
#' @param antigen Coverage antigen passed to [get_coverage()].
#' @param disease Cases disease passed to [get_cases()].
#' @param years Optional integer vector.
#' @param countries Optional ISO3 vector.
#' @param demography_source Demography source passed to [get_demography()].
#' @param indicator_set Indicator registry mode for measles-related indicators.
#'   One of `\"explicit\"`, `\"dynamic\"`, `\"both\"`. Stored as panel attribute.
#' @param coverage Optional precomputed coverage tibble (`iso3`, `year`, `coverage`).
#' @param cases Optional precomputed cases tibble (`iso3`, `year`, `cases`).
#' @param demography Optional precomputed demography tibble.
#' @param country_metadata Optional precomputed country metadata tibble.
#'
#' @return A [vpd_panel].
#' @export
build_panel_from_sources <- function(
    antigen = "MCV1",
    disease = "measles",
    years = NULL,
    countries = NULL,
    demography_source = getOption("vpdsus.demography_source", "example"),
    indicator_set = c("explicit", "dynamic", "both"),
    coverage = NULL,
    cases = NULL,
    demography = NULL,
    country_metadata = NULL) {
  indicator_set <- match.arg(indicator_set)
  cov <- if (is.null(coverage)) get_coverage(antigen = antigen, years = years, countries = countries) else coverage
  cas <- if (is.null(cases)) get_cases(disease = disease, years = years, countries = countries) else cases
  dem <- if (is.null(demography)) get_demography(years = years, countries = countries, source = demography_source) else demography
  meta <- if (is.null(country_metadata)) {
    tryCatch(
      get_country_metadata(),
      error = function(e) {
        p <- system.file("extdata", "country_metadata_small.csv", package = "vpdsus")
        if (!nzchar(p)) {
          cli::cli_abort("Could not retrieve country metadata and no fallback file is available")
        }
        tibble::as_tibble(utils::read.csv(p, stringsAsFactors = FALSE))
      }
    )
  } else {
    country_metadata
  }
  out <- build_panel(cov, cas, dem, country_metadata = meta)
  attr(out, "indicator_set") <- indicator_set
  out
}

#' Summarise age groups from age-structured demography
#'
#' @param demography A data.frame containing `iso3`, `year`, `age`, `pop`, and optionally `births`.
#' @param groups Named list mapping output group names to integer age vectors.
#'
#' @return tibble with one row per iso3-year and one column per requested age group.
#' @export
summarise_age_groups <- function(
    demography,
    groups = list(pop_0_4 = 0:4, pop_5_14 = 5:14)) {
  assert_has_cols(demography, c("iso3", "year", "age", "pop"))

  df <- tibble::as_tibble(demography) |>
    dplyr::mutate(
      iso3 = standardise_iso3(.data$iso3),
      year = as.integer(.data$year),
      age = as.integer(.data$age),
      pop = as.numeric(.data$pop)
    )

  out <- df |>
    dplyr::group_by(.data$iso3, .data$year) |>
    dplyr::summarise(pop_total = sum(.data$pop, na.rm = TRUE), .groups = "drop")

  for (nm in names(groups)) {
    ages <- as.integer(groups[[nm]])
    tmp <- df |>
      dplyr::filter(.data$age %in% ages) |>
      dplyr::group_by(.data$iso3, .data$year) |>
      dplyr::summarise(val = sum(.data$pop, na.rm = TRUE), .groups = "drop")
    names(tmp)[names(tmp) == "val"] <- nm
    out <- dplyr::left_join(out, tmp, by = c("iso3", "year"))
  }

  if ("births" %in% names(demography)) {
    births <- tibble::as_tibble(demography) |>
      dplyr::mutate(
        iso3 = standardise_iso3(.data$iso3),
        year = as.integer(.data$year),
        births = as.numeric(.data$births)
      ) |>
      dplyr::group_by(.data$iso3, .data$year) |>
      dplyr::summarise(births = dplyr::first(.data$births), .groups = "drop")
    out <- dplyr::left_join(out, births, by = c("iso3", "year"))
  }

  out
}

#' Unified susceptibility interface
#'
#' @param panel A panel data.frame/tibble.
#' @param method One of `static`, `cohort`, `cohort_ve`, `case_balance`.
#' @param ... Additional arguments passed to the selected estimator.
#'
#' @return Susceptibility tibble.
#' @export
estimate_susceptible <- function(panel, method = c("static", "cohort", "cohort_ve", "case_balance"), ...) {
  method <- match.arg(method)
  switch(
    method,
    static = estimate_susceptible_static(panel, ...),
    cohort = estimate_susceptible_cohort(panel, ...),
    cohort_ve = estimate_susceptible_cohort_ve(panel, ...),
    case_balance = estimate_susceptible_case_balance(panel, ...),
    cli::cli_abort("Unknown method: {method}")
  )
}

#' Prepare odin2 inputs from panel
#'
#' @param panel A panel with births/coverage/cases.
#' @param times Times (typically years).
#' @param iso3 Country ISO3.
#' @param ... Passed to [odin2_balance_inputs_from_panel()].
#'
#' @return Named list of input vectors.
#' @export
odin2_prepare_inputs <- function(panel, times, iso3, ...) {
  odin2_balance_inputs_from_panel(panel = panel, times = times, iso3 = iso3, ...)
}

#' Estimate susceptibility trajectory via mechanistic simulation
#'
#' @param panel A panel data.frame.
#' @param iso3 Country ISO3.
#' @param times Optional times vector; defaults to panel years for `iso3`.
#' @param model Mechanistic model name.
#' @param pars Additional parameters list.
#' @param initial Initial state list.
#'
#' @return tibble with iso3, year, susceptible_n, susceptible_prop, method.
#' @export
estimate_susceptible_mechanistic <- function(
    panel,
    iso3,
    times = NULL,
    model = "balance_discrete",
    pars = list(rho = 1),
    initial = list(S = 0)) {
  assert_is_scalar_chr(iso3)
  assert_has_cols(panel, c("iso3", "year", "pop_total", "births", "coverage", "cases"))

  panel_iso <- tibble::as_tibble(panel) |>
    dplyr::mutate(iso3 = standardise_iso3(.data$iso3), year = as.integer(.data$year)) |>
    dplyr::filter(.data$iso3 == standardise_iso3(iso3)) |>
    dplyr::arrange(.data$year)

  if (nrow(panel_iso) == 0) {
    cli::cli_abort("No rows in panel for iso3={iso3}")
  }

  if (is.null(times)) {
    times <- sort(unique(panel_iso$year))
  }

  inputs <- odin2_prepare_inputs(panel_iso, times = times, iso3 = iso3)
  sim <- odin2_simulate(model = model, times = times, pars = pars, initial = initial, inputs = inputs)

  susceptible_n <- as.numeric(sim$S)
  pop_total <- as.numeric(panel_iso$pop_total[match(as.integer(sim$time), panel_iso$year)])
  susceptible_prop <- susceptible_n / pop_total

  out <- tibble::tibble(
    iso3 = standardise_iso3(iso3),
    year = as.integer(sim$time),
    susceptible_n = susceptible_n,
    pop_total = pop_total,
    susceptible_prop = susceptible_prop,
    method = "mechanistic"
  )
  dplyr::select(out, .data$iso3, .data$year, .data$susceptible_n, .data$susceptible_prop, .data$method)
}

#' Infer mechanistic susceptibility by calibrating rho then simulating
#'
#' @param panel A panel data.frame.
#' @param iso3 Country ISO3.
#' @param years Years used for calibration/simulation.
#' @param target_year Calibration target year.
#' @param target_susceptible_n Target susceptible count at `target_year`.
#' @param rho_interval Search interval for rho.
#' @param s0 Optional initial susceptible count.
#'
#' @return tibble susceptibility trajectory with fitted rho in column `rho`.
#' @export
infer_susceptibility_mechanistic <- function(
    panel,
    iso3,
    years,
    target_year,
    target_susceptible_n,
    rho_interval = c(1e-4, 1),
    s0 = NULL) {
  rho_hat <- calibrate_rho_case_balance(
    panel = panel,
    iso3 = iso3,
    years = years,
    target_year = target_year,
    target_susceptible_n = target_susceptible_n,
    s0 = s0,
    rho_interval = rho_interval
  )

  out <- estimate_susceptible_mechanistic(
    panel = panel,
    iso3 = iso3,
    times = years,
    model = "balance_discrete",
    pars = list(rho = rho_hat),
    initial = if (is.null(s0)) list(S = 0) else list(S = as.numeric(s0))
  )
  dplyr::mutate(out, rho = rho_hat)
}

#' Fit simple mechanistic calibration model
#'
#' @inheritParams infer_susceptibility_mechanistic
#'
#' @return List with fitted `rho` and `trajectory`.
#' @export
fit_mechanistic_model <- function(
    panel,
    iso3,
    years,
    target_year,
    target_susceptible_n,
    rho_interval = c(1e-4, 1),
    s0 = NULL) {
  tr <- infer_susceptibility_mechanistic(
    panel = panel,
    iso3 = iso3,
    years = years,
    target_year = target_year,
    target_susceptible_n = target_susceptible_n,
    rho_interval = rho_interval,
    s0 = s0
  )
  list(rho = tr$rho[[1]], trajectory = tr)
}

#' Coverage ranking plot faceted by WHO region
#'
#' @param rank_tbl Output of [risk_rank()].
#' @param top_n Number of rows to display.
#'
#' @return A ggplot object.
#' @export
plot_coverage_rank_by_region <- function(rank_tbl, top_n = 50) {
  df <- tibble::as_tibble(rank_tbl) |>
    dplyr::slice_head(n = top_n) |>
    dplyr::mutate(
      who_region = dplyr::coalesce(as.character(.data$who_region), "UNK"),
      country = factor(.data$country, levels = rev(unique(.data$country)))
    )

  ggplot2::ggplot(df, ggplot2::aes(x = .data$coverage_mean, y = .data$country, fill = .data$risk_category)) +
    ggplot2::geom_col(width = 0.8) +
    ggplot2::facet_wrap(~who_region, scales = "free_y") +
    ggplot2::scale_x_continuous(labels = scales::percent_format(accuracy = 1)) +
    ggplot2::labs(x = "Mean coverage", y = NULL, fill = "Risk category", title = "Coverage ranking by region") +
    vpdsus_theme()
}

#' Stack plot of susceptible counts by age group
#'
#' @param suscept Susceptibility tibble with `iso3`, `year`, `age_group`, and `susceptible_n`.
#' @param iso3 Optional ISO3 filter.
#'
#' @return A ggplot object.
#' @export
plot_susceptible_stack_by_age <- function(suscept, iso3 = NULL) {
  assert_has_cols(suscept, c("iso3", "year", "age_group", "susceptible_n"))
  df <- tibble::as_tibble(suscept) |>
    dplyr::mutate(iso3 = standardise_iso3(.data$iso3), year = as.integer(.data$year))

  if (!is.null(iso3)) {
    df <- dplyr::filter(df, .data$iso3 == standardise_iso3(iso3))
  } else {
    df <- dplyr::filter(df, .data$iso3 == dplyr::first(.data$iso3))
  }

  ggplot2::ggplot(df, ggplot2::aes(x = .data$year, y = .data$susceptible_n, fill = .data$age_group)) +
    ggplot2::geom_area(alpha = 0.85) +
    ggplot2::labs(x = "Year", y = "Susceptible (n)", fill = "Age group", title = paste("Susceptible stack:", unique(df$iso3))) +
    vpdsus_theme()
}

#' WHO-style dashboard summary plot
#'
#' @param rank_tbl Output of [risk_rank()].
#' @param top_n Number of rows to display.
#'
#' @return A ggplot object.
#' @export
plot_who_style_dashboard <- function(rank_tbl, top_n = 30) {
  df <- tibble::as_tibble(rank_tbl) |>
    dplyr::slice_head(n = top_n) |>
    dplyr::mutate(
      country = factor(.data$country, levels = rev(.data$country)),
      who_region = dplyr::coalesce(as.character(.data$who_region), "UNK")
    )

  ggplot2::ggplot(df, ggplot2::aes(x = .data$coverage_mean, y = .data$susceptible_prop, colour = .data$risk_category)) +
    ggplot2::geom_point(size = 2.4, alpha = 0.9) +
    ggplot2::facet_wrap(~who_region) +
    ggplot2::scale_x_continuous(labels = scales::percent_format(accuracy = 1)) +
    ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
    ggplot2::labs(
      x = "Recent mean coverage",
      y = "Susceptible proportion",
      colour = "Risk category",
      title = "WHO-style susceptibility dashboard"
    ) +
    vpdsus_theme()
}
