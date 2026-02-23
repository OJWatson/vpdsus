#' Build a country-year panel
#'
#' @param coverage tibble from [get_coverage()] (iso3, year, coverage).
#' @param cases tibble from [get_cases()] (iso3, year, cases).
#' @param demography tibble from [get_demography()].
#' @param country_metadata Optional tibble from [get_country_metadata()] with at
#'   least iso3, country, who_region. If provided, will be joined onto the panel.
#'
#' @return A tibble with class 'vpd_panel'.
#' @export
build_panel <- function(coverage, cases, demography, country_metadata = NULL) {
  assert_has_cols(coverage, c("iso3", "year", "coverage"), "coverage")
  assert_has_cols(cases, c("iso3", "year", "cases"), "cases")
  assert_has_cols(demography, c("iso3", "year", "pop_total", "pop_0_4", "pop_5_14", "births"), "demography")

  coverage <- tibble::as_tibble(coverage) |>
    dplyr::mutate(
      iso3 = standardise_iso3(.data$iso3),
      year = as.integer(.data$year),
      coverage = as.numeric(.data$coverage)
    )
  cases <- tibble::as_tibble(cases) |>
    dplyr::mutate(
      iso3 = standardise_iso3(.data$iso3),
      year = as.integer(.data$year),
      cases = as.numeric(.data$cases)
    )
  demography <- tibble::as_tibble(demography) |>
    dplyr::mutate(
      iso3 = standardise_iso3(.data$iso3),
      year = as.integer(.data$year)
    )

  assert_unique_key(coverage, c("iso3", "year"), name = "coverage")
  assert_unique_key(cases, c("iso3", "year"), name = "cases")
  assert_unique_key(demography, c("iso3", "year"), name = "demography")

  panel <- dplyr::full_join(demography, coverage, by = c("iso3", "year")) |>
    dplyr::full_join(cases, by = c("iso3", "year"))

  if (!is.null(country_metadata)) {
    assert_has_cols(country_metadata, c("iso3"), "country_metadata")
    country_metadata <- tibble::as_tibble(country_metadata) |>
      dplyr::mutate(iso3 = standardise_iso3(.data$iso3))
    assert_unique_key(country_metadata, c("iso3"), name = "country_metadata")

    panel <- dplyr::left_join(panel, country_metadata, by = "iso3")
  }

  panel <- dplyr::arrange(panel, .data$iso3, .data$year)

  diag <- dplyr::summarise(
    panel,
    n = dplyr::n(),
    missing_coverage = sum(is.na(.data$coverage)),
    missing_cases = sum(is.na(.data$cases)),
    missing_pop = sum(is.na(.data$pop_total))
  )

  class(panel) <- c("vpd_panel", class(panel))
  attr(panel, "diagnostics") <- diag
  panel
}

#' Extract join diagnostics from a panel
#'
#' @param panel vpd_panel from [build_panel()].
#' @return tibble.
#' @export
panel_diagnostics <- function(panel) {
  attr(panel, "diagnostics") %||% tibble::tibble()
}

#' Validate panel schema and value constraints
#'
#' Performs lightweight schema and range checks for a country-year panel.
#' This is intended as a practical guardrail before susceptibility or modelling
#' steps, not as a strict data contract system.
#'
#' @param panel A data.frame/tibble, typically from [build_panel()].
#' @param required_cols Character vector of required columns.
#' @param key_cols Key columns that should uniquely identify rows.
#' @param quiet If `TRUE`, do not emit warning messages when issues are found.
#'
#' @return A list with:
#' - `ok`: `TRUE` if no issues were found.
#' - `issues`: tibble of issue messages.
#' - `diagnostics`: tibble summary with row/country/year coverage.
#'
#' @examples
#' panel <- vpdsus_example_panel()
#' v <- panel_validate(panel)
#' v$ok
#' v$issues
#'
#' @export
panel_validate <- function(
    panel,
    required_cols = c("iso3", "year", "coverage", "cases", "pop_total", "births"),
    key_cols = c("iso3", "year"),
    quiet = FALSE) {
  issues <- character()

  if (!is.data.frame(panel)) {
    issues <- c(issues, "`panel` must be a data.frame/tibble")
    out <- list(
      ok = FALSE,
      issues = tibble::tibble(issue = issues),
      diagnostics = tibble::tibble(
        n_rows = NA_integer_,
        n_iso3 = NA_integer_,
        year_min = NA_integer_,
        year_max = NA_integer_
      )
    )
    return(out)
  }

  panel <- tibble::as_tibble(panel)

  missing <- setdiff(required_cols, names(panel))
  if (length(missing) > 0) {
    issues <- c(issues, paste0("missing required columns: ", paste(missing, collapse = ", ")))
  }

  has_key_cols <- all(key_cols %in% names(panel))
  if (!has_key_cols) {
    issues <- c(issues, paste0("missing key columns: ", paste(setdiff(key_cols, names(panel)), collapse = ", ")))
  }

  if ("iso3" %in% names(panel)) {
    bad_iso <- sum(is.na(panel$iso3) | trimws(as.character(panel$iso3)) == "")
    if (bad_iso > 0) {
      issues <- c(issues, paste0("iso3 has ", bad_iso, " missing/blank value(s)"))
    }
  }

  if ("year" %in% names(panel)) {
    bad_year <- sum(is.na(panel$year) | !is.finite(as.numeric(panel$year)))
    if (bad_year > 0) {
      issues <- c(issues, paste0("year has ", bad_year, " missing/non-finite value(s)"))
    }
  }

  if ("coverage" %in% names(panel)) {
    bad_cov <- sum(!is.na(panel$coverage) & (as.numeric(panel$coverage) < 0 | as.numeric(panel$coverage) > 1))
    if (bad_cov > 0) {
      issues <- c(issues, paste0("coverage has ", bad_cov, " value(s) outside [0, 1]"))
    }
  }

  if ("cases" %in% names(panel)) {
    bad_cases <- sum(!is.na(panel$cases) & as.numeric(panel$cases) < 0)
    if (bad_cases > 0) {
      issues <- c(issues, paste0("cases has ", bad_cases, " negative value(s)"))
    }
  }

  nonnegative_cols <- intersect(c("births", "pop_total", "pop_0_4", "pop_5_14"), names(panel))
  if (length(nonnegative_cols) > 0) {
    for (col in nonnegative_cols) {
      bad_n <- sum(!is.na(panel[[col]]) & as.numeric(panel[[col]]) < 0)
      if (bad_n > 0) {
        issues <- c(issues, paste0(col, " has ", bad_n, " negative value(s)"))
      }
    }
  }

  if (has_key_cols) {
    dupes <- panel |>
      dplyr::count(dplyr::across(dplyr::all_of(key_cols)), name = "n") |>
      dplyr::filter(.data$n > 1)
    if (nrow(dupes) > 0) {
      issues <- c(issues, paste0("duplicated rows detected for key: ", paste(key_cols, collapse = "+")))
    }
  }

  diagnostics <- tibble::tibble(
    n_rows = nrow(panel),
    n_iso3 = if ("iso3" %in% names(panel)) dplyr::n_distinct(panel$iso3, na.rm = TRUE) else NA_integer_,
    year_min = if ("year" %in% names(panel)) suppressWarnings(min(as.integer(panel$year), na.rm = TRUE)) else NA_integer_,
    year_max = if ("year" %in% names(panel)) suppressWarnings(max(as.integer(panel$year), na.rm = TRUE)) else NA_integer_
  )

  if (is.infinite(diagnostics$year_min)) diagnostics$year_min <- NA_integer_
  if (is.infinite(diagnostics$year_max)) diagnostics$year_max <- NA_integer_

  out <- list(
    ok = length(issues) == 0,
    issues = tibble::tibble(issue = issues),
    diagnostics = diagnostics
  )

  if (!quiet && length(issues) > 0) {
    cli::cli_warn(c(
      "Panel validation found issues:",
      paste0("- ", issues)
    ))
  }

  out
}
