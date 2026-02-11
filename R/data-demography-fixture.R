# WPP-like fixture adapter (deterministic; no network)

#' Convert a pinned WPP-like demography fixture into standardised demography output
#'
#' The fixture is intentionally tiny and exists to validate the transformation
#' contract without relying on non-CRAN data packages or network access.
#'
#' Expected columns: iso3, year, age, pop, births.
#'
#' @param years Optional integer vector.
#' @param countries Optional ISO3 vector.
#' @return tibble with iso3, year, pop_total, pop_0_4, pop_5_14, births.
#'
#' @keywords internal
#' @noRd
demography_from_wpp_like_fixture <- function(years = NULL, countries = NULL) {
  path <- system.file("extdata", "demography_wpp_like_small.csv", package = "vpdsus")
  if (identical(path, "")) {
    cli::cli_abort("Could not find demography fixture file in inst/extdata")
  }
  df <- utils::read.csv(path, stringsAsFactors = FALSE)
  df <- tibble::as_tibble(df) |>
    dplyr::mutate(
      iso3 = standardise_iso3(.data$iso3),
      year = as.integer(.data$year),
      age = as.integer(.data$age),
      pop = as.numeric(.data$pop),
      births = as.numeric(.data$births)
    )

  if (!is.null(years)) df <- dplyr::filter(df, .data$year %in% as.integer(years))
  if (!is.null(countries)) df <- dplyr::filter(df, .data$iso3 %in% standardise_iso3(countries))

  out <- df |>
    dplyr::group_by(.data$iso3, .data$year) |>
    dplyr::summarise(
      pop_total = sum(.data$pop, na.rm = TRUE),
      pop_0_4 = sum(.data$pop[.data$age %in% 0:4], na.rm = TRUE),
      pop_5_14 = sum(.data$pop[.data$age %in% 5:14], na.rm = TRUE),
      births = dplyr::first(.data$births),
      .groups = "drop"
    )

  out
}
