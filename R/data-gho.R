gho_base_url <- function() {
  "https://ghoapi.azureedge.net/api"
}

#' Low-level GET for WHO GHO OData
#'
#' @param endpoint Character, e.g. "Indicator" or an indicator code.
#' @param query Named list of OData query parameters.
#' @param cache Logical; cache raw JSON.
#' @param quiet Logical.
#'
#' @return A tibble.
#' @export
gho_get <- function(endpoint, query = list(), cache = TRUE, quiet = TRUE) {
  assert_is_scalar_chr(endpoint)

  # Build URL
  base <- gho_base_url()
  url <- paste0(base, "/", endpoint)
  if (length(query)) {
    qs <- paste0(utils::URLencode(names(query)), "=", utils::URLencode(as.character(query)), collapse = "&")
    url <- paste0(url, "?", qs)
  }

  key <- paste0(gsub("[^A-Za-z0-9]+", "_", endpoint), "_", hash_list(list(url = url)))
  path <- cache_paths(key, ext = "json")

  if (cache && file.exists(path)) {
    txt <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  } else {
    if (!quiet) cli::cli_inform("Downloading {url}")
    con <- url(url)
    on.exit(try(close(con), silent = TRUE), add = TRUE)
    txt <- paste(readLines(con, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
    if (cache) {
      dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
      writeLines(txt, path, useBytes = TRUE)
    }
  }

  parsed <- jsonlite::fromJSON(txt, simplifyVector = TRUE)

  # Most endpoints return a list with $value
  value <- parsed$value %||% parsed
  tibble::as_tibble(value)
}

`%||%` <- function(x, y) if (is.null(x)) y else x

#' Search GHO indicator metadata by keyword
#'
#' @param keyword Keyword to search within IndicatorName.
#' @param top_n Maximum number of results.
#'
#' @return tibble with indicator codes and names.
#' @export
gho_find_indicator <- function(keyword, top_n = 50) {
  assert_is_scalar_chr(keyword)
  q <- list(
    `$filter` = sprintf("contains(IndicatorName,'%s')", gsub("'", "''", keyword)),
    `$top` = top_n
  )
  out <- gho_get("Indicator", query = q)
  dplyr::transmute(
    out,
    indicator_code = .data$IndicatorCode,
    indicator_name = .data$IndicatorName
  )
}

#' Download all data for an indicator code
#'
#' @param indicator_code Indicator code (e.g., "MCV1").
#' @return tibble.
#' @export
gho_get_indicator <- function(indicator_code) {
  assert_is_scalar_chr(indicator_code)
  gho_get(indicator_code)
}

#' Built-in mapping of common indicators
#'
#' @return tibble.
#' @export
vpd_indicators <- function() {
  tibble::tibble(
    key = c(
      "mcv1_coverage",
      "mcv2_coverage",
      "measles_cases",
      "dtp1_coverage",
      "dtp3_coverage"
    ),
    type = c("coverage", "coverage", "cases", "coverage", "coverage"),
    antigen_or_disease = c("MCV1", "MCV2", "measles", "DTP1", "DTP3"),
    indicator_code = c(
      # WHO GHO indicator codes are discoverable and may change; users can override.
      # These defaults are placeholders that work for discovery via vignette.
      "MCV1",
      "MCV2",
      "MEASLESCASES",
      "DTP1",
      "DTP3"
    )
  )
}

#' Get vaccination coverage series
#'
#' @param antigen Antigen string (e.g., "MCV1", "DTP3").
#' @param indicator_code Optional explicit indicator code.
#' @param years Optional integer vector.
#' @param countries Optional ISO3 vector.
#' @return tibble with iso3, year, coverage.
#' @export
get_coverage <- function(antigen, indicator_code = NULL, years = NULL, countries = NULL) {
  assert_is_scalar_chr(antigen)

  if (is.null(indicator_code)) {
    map <- vpd_indicators()
    row <- dplyr::filter(map, .data$type == "coverage", .data$antigen_or_disease == antigen)
    if (nrow(row) == 0) {
      cli::cli_abort("No default indicator mapping for antigen {antigen}. Provide indicator_code explicitly.")
    }
    indicator_code <- row$indicator_code[[1]]
  }

  raw <- gho_get_indicator(indicator_code)

  # Try to standardise common GHO column names
  out <- dplyr::transmute(
    raw,
    iso3 = standardise_iso3(.data$SpatialDim %||% .data$SpatialDimValueCode %||% .data$COUNTRY_CODE),
    year = as.integer(.data$TimeDim %||% .data$TimeDimValueCode %||% .data$YEAR),
    coverage = as.numeric(.data$Value)
  )

  out <- dplyr::filter(out, !is.na(.data$iso3), !is.na(.data$year))
  # Normalise to proportion in [0,1]
  out <- dplyr::mutate(out, coverage = dplyr::if_else(.data$coverage > 1, .data$coverage / 100, .data$coverage))

  if (!is.null(years)) out <- dplyr::filter(out, .data$year %in% years)
  if (!is.null(countries)) out <- dplyr::filter(out, .data$iso3 %in% standardise_iso3(countries))

  dplyr::distinct(out, .data$iso3, .data$year, .keep_all = TRUE)
}

#' Get reported cases series
#'
#' @param disease Disease string (e.g., "measles").
#' @param indicator_code Optional explicit indicator code.
#' @param years Optional integer vector.
#' @param countries Optional ISO3 vector.
#' @return tibble with iso3, year, cases, cases_per_100k.
#' @export
get_cases <- function(disease, indicator_code = NULL, years = NULL, countries = NULL) {
  assert_is_scalar_chr(disease)

  if (is.null(indicator_code)) {
    map <- vpd_indicators()
    row <- dplyr::filter(map, .data$type == "cases", .data$antigen_or_disease == disease)
    if (nrow(row) == 0) {
      cli::cli_abort("No default indicator mapping for disease {disease}. Provide indicator_code explicitly.")
    }
    indicator_code <- row$indicator_code[[1]]
  }

  raw <- gho_get_indicator(indicator_code)
  out <- dplyr::transmute(
    raw,
    iso3 = standardise_iso3(.data$SpatialDim %||% .data$SpatialDimValueCode %||% .data$COUNTRY_CODE),
    year = as.integer(.data$TimeDim %||% .data$TimeDimValueCode %||% .data$YEAR),
    cases = as.numeric(.data$Value)
  )

  out <- dplyr::filter(out, !is.na(.data$iso3), !is.na(.data$year))
  if (!is.null(years)) out <- dplyr::filter(out, .data$year %in% years)
  if (!is.null(countries)) out <- dplyr::filter(out, .data$iso3 %in% standardise_iso3(countries))

  dplyr::distinct(out, .data$iso3, .data$year, .keep_all = TRUE)
}
