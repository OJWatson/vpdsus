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
