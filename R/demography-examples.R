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
#' Get demography series
#'
#' @description
#' Retrieves demography required for susceptibility estimation.
#' By default, derives demography from the shipped global measles example panel.
#' A deterministic fixture backend is also provided for focused tests.
#'
#' @param years Optional integer vector.
#' @param countries Optional ISO3 vector.
#' @param source One of "example" (default) or "fixture_wpp".
#'   You can set a global default via `options(vpdsus.demography_source = "fixture_wpp")`.
#' @param cache Logical; if `TRUE` (default) cache the computed demography tibble.
#'
#' @return tibble with iso3, year, pop_total, pop_0_4, pop_5_14, births.
#' @export
get_demography <- function(
  years = NULL,
  countries = NULL,
  source = getOption("vpdsus.demography_source", "example"),
  cache = TRUE
) {
  source <- match.arg(source, choices = c("example", "fixture_wpp"))

  key <- demography_cache_key(source = source, years = years, countries = countries)
  path <- cache_paths_demography(key, ext = "rds")

  if (isTRUE(cache) && file.exists(path)) {
    return(readRDS(path))
  }

  if (source == "fixture_wpp") {
    out <- demography_from_wpp_like_fixture(years = years, countries = countries)
    if (isTRUE(cache)) saveRDS(out, path)
    return(out)
  }

  panel <- vpdsus_example_panel()
  out <- dplyr::distinct(panel, .data$iso3, .data$year, .data$pop_total, .data$pop_0_4, .data$pop_5_14, .data$births)

  if (!is.null(years)) out <- dplyr::filter(out, .data$year %in% as.integer(years))
  if (!is.null(countries)) out <- dplyr::filter(out, .data$iso3 %in% standardise_iso3(countries))

  if (isTRUE(cache)) saveRDS(out, path)
  out
}

# Stable cache key for demography accessor
# (Order-insensitive for years/countries; not exported)

demography_cache_key <- function(source, years = NULL, countries = NULL) {
  assert_is_scalar_chr(source)

  yrs <- years
  if (!is.null(yrs)) {
    yrs <- sort(unique(as.integer(yrs)))
  }

  ctry <- countries
  if (!is.null(ctry)) {
    ctry <- sort(unique(standardise_iso3(ctry)))
  }

  paste0("demog_", source, "_", hash_list(list(source = source, years = yrs, countries = ctry)))
}

#' Example panel shipped with the package
#'
#' @return A tibble.
#' @export
vpdsus_example_panel <- function() {
  path <- system.file("extdata", "example_panel_measles_global.csv", package = "vpdsus")
  out <- read.csv(path, stringsAsFactors = FALSE)
  tibble::as_tibble(out) |>
    dplyr::mutate(
      iso3 = standardise_iso3(.data$iso3),
      year = as.integer(.data$year),
      coverage = as.numeric(.data$coverage),
      cases = as.numeric(.data$cases),
      pop_total = as.numeric(.data$pop_total),
      pop_0_4 = as.numeric(.data$pop_0_4),
      pop_5_14 = as.numeric(.data$pop_5_14),
      births = as.numeric(.data$births)
    )
}
