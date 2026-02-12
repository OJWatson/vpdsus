#' Get demography series
#'
#' @description
#' Retrieves demography required for susceptibility estimation.
#' By default, uses a small shipped example dataset for vignettes and tests.
#' A full implementation can be added via WPP (Suggests) or other APIs.
#'
#' @param years Optional integer vector.
#' @param countries Optional ISO3 vector.
#' @param source One of "example" (default) or "fixture_wpp".
#'
#' @return tibble with iso3, year, pop_total, pop_0_4, pop_5_14, births.
#' @export
get_demography <- function(years = NULL, countries = NULL, source = c("example", "fixture_wpp")) {
  source <- match.arg(source)

  if (source == "fixture_wpp") {
    out <- demography_from_wpp_like_fixture(years = years, countries = countries)
    return(out)
  }

  panel <- vpdsus_example_panel()
  out <- dplyr::distinct(panel, .data$iso3, .data$year, .data$pop_total, .data$pop_0_4, .data$pop_5_14, .data$births)

  if (!is.null(years)) out <- dplyr::filter(out, .data$year %in% years)
  if (!is.null(countries)) out <- dplyr::filter(out, .data$iso3 %in% standardise_iso3(countries))

  out
}

#' Example panel shipped with the package
#'
#' @return A tibble.
#' @export
vpdsus_example_panel <- function() {
  path <- system.file("extdata", "example_panel_small.csv", package = "vpdsus")
  out <- read.csv(path, stringsAsFactors = FALSE)
  tibble::as_tibble(out) |>
    dplyr::mutate(
      iso3 = standardise_iso3(.data$iso3),
      year = as.integer(.data$year)
    )
}
