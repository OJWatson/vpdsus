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
