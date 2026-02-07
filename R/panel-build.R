#' Build a country-year panel
#'
#' @param coverage tibble from [get_coverage()] (iso3, year, coverage).
#' @param cases tibble from [get_cases()] (iso3, year, cases).
#' @param demography tibble from [get_demography()].
#'
#' @return A tibble with class 'vpd_panel'.
#' @export
build_panel <- function(coverage, cases, demography) {
  assert_has_cols(coverage, c("iso3", "year", "coverage"), "coverage")
  assert_has_cols(cases, c("iso3", "year", "cases"), "cases")
  assert_has_cols(demography, c("iso3", "year", "pop_total", "pop_0_4", "pop_5_14", "births"), "demography")

  coverage <- dplyr::mutate(coverage, iso3 = standardise_iso3(.data$iso3), year = as.integer(.data$year))
  cases <- dplyr::mutate(cases, iso3 = standardise_iso3(.data$iso3), year = as.integer(.data$year))
  demography <- dplyr::mutate(demography, iso3 = standardise_iso3(.data$iso3), year = as.integer(.data$year))

  panel <- dplyr::full_join(demography, coverage, by = c("iso3", "year")) |>
    dplyr::full_join(cases, by = c("iso3", "year"))

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
