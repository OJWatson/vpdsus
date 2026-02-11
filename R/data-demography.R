#' Get demography series
#'
#' @description
#' Retrieves demography required for susceptibility estimation.
#' By default, uses a small shipped example dataset for vignettes and tests.
#' A full implementation can be added via WPP (Suggests) or other APIs.
#'
#' @param years Optional integer vector.
#' @param countries Optional ISO3 vector.
#' @param source One of "example" (default), "wpp" (optional), or "fixture_wpp".
#'
#' @return tibble with iso3, year, pop_total, pop_0_4, pop_5_14, births.
#' @export
get_demography <- function(years = NULL, countries = NULL, source = c("example", "fixture_wpp", "wpp")) {
  source <- match.arg(source)

  if (source == "wpp") {
    if (!requireNamespace("wpp2024", quietly = TRUE)) {
      cli::cli_abort("Package {.pkg wpp2024} is required for source='wpp'. Install it or use source='example'/'fixture_wpp'.")
    }

    wpp_demography <- wpp_get_demography(years = years, countries = countries)
    return(wpp_demography)
  }

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

wpp_get_demography <- function(years = NULL, countries = NULL) {
  # This adapter is intentionally defensive because the {wpp2024} package is a
  # data package and its object names/column conventions may evolve.
  ns <- asNamespace("wpp2024")

  # Try common object names used across WPP R data packages
  pop_obj <- get0("pop", envir = ns, inherits = FALSE)
  if (is.null(pop_obj)) pop_obj <- get0("pop_total", envir = ns, inherits = FALSE)
  if (is.null(pop_obj)) pop_obj <- get0("popM", envir = ns, inherits = FALSE)

  births_obj <- get0("births", envir = ns, inherits = FALSE)

  if (is.null(pop_obj) || is.null(births_obj)) {
    cli::cli_abort(
      "Could not find expected population/births objects in {.pkg wpp2024}. ",
      "Please file an issue with your wpp2024 version and object names."
    )
  }

  pop <- tibble::as_tibble(pop_obj)
  births <- tibble::as_tibble(births_obj)

  # Guess column names
  iso_col <- intersect(names(pop), c("iso3c", "iso3", "ISO3", "country_code"))[[1]] %||% NA_character_
  year_col <- intersect(names(pop), c("year", "Year"))[[1]] %||% NA_character_
  age_col <- intersect(names(pop), c("age", "Age"))[[1]] %||% NA_character_
  val_col <- intersect(names(pop), c("pop", "Pop", "value", "Value"))[[1]] %||% NA_character_

  if (anyNA(c(iso_col, year_col, age_col, val_col))) {
    cli::cli_abort(
      "Unrecognised column names in population table from {.pkg wpp2024}. ",
      "Expected columns for iso3/year/age/value; got: {names(pop)}"
    )
  }

  pop <- dplyr::transmute(
    pop,
    iso3 = standardise_iso3(.data[[iso_col]]),
    year = as.integer(.data[[year_col]]),
    age = as.integer(.data[[age_col]]),
    value = as.numeric(.data[[val_col]])
  )

  # Births
  iso_col_b <- intersect(names(births), c("iso3c", "iso3", "ISO3", "country_code"))[[1]] %||% NA_character_
  year_col_b <- intersect(names(births), c("year", "Year"))[[1]] %||% NA_character_
  val_col_b <- intersect(names(births), c("births", "Births", "value", "Value"))[[1]] %||% NA_character_
  if (anyNA(c(iso_col_b, year_col_b, val_col_b))) {
    cli::cli_abort(
      "Unrecognised column names in births table from {.pkg wpp2024}. ",
      "Expected iso3/year/births; got: {names(births)}"
    )
  }

  births <- dplyr::transmute(
    births,
    iso3 = standardise_iso3(.data[[iso_col_b]]),
    year = as.integer(.data[[year_col_b]]),
    births = as.numeric(.data[[val_col_b]])
  )

  if (!is.null(years)) {
    pop <- dplyr::filter(pop, .data$year %in% years)
    births <- dplyr::filter(births, .data$year %in% years)
  }
  if (!is.null(countries)) {
    cc <- standardise_iso3(countries)
    pop <- dplyr::filter(pop, .data$iso3 %in% cc)
    births <- dplyr::filter(births, .data$iso3 %in% cc)
  }

  pop_sum <- pop |>
    dplyr::group_by(.data$iso3, .data$year) |>
    dplyr::summarise(
      pop_total = sum(.data$value, na.rm = TRUE),
      pop_0_4 = sum(.data$value[.data$age %in% 0:4], na.rm = TRUE),
      pop_5_14 = sum(.data$value[.data$age %in% 5:14], na.rm = TRUE),
      .groups = "drop"
    )

  dplyr::left_join(pop_sum, births, by = c("iso3", "year")) |>
    tidyr::drop_na(.data$iso3, .data$year)
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
