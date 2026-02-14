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

  url <- gho_build_url(endpoint, query)

  key <- gho_cache_key(endpoint, query)
  path <- cache_paths(key, ext = "json")

  if (cache && file.exists(path)) {
    txt <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  } else {
    if (!quiet) cli::cli_inform("Downloading {url}")

    if (!requireNamespace("httr2", quietly = TRUE)) {
      cli::cli_abort("Package {.pkg httr2} is required to download GHO data")
    }

    resp <- httr2::request(url) |>
      httr2::req_user_agent("vpdsus (https://github.com/OJWatson/vpdsus)") |>
      httr2::req_retry(max_tries = 3) |>
      httr2::req_perform()

    txt <- httr2::resp_body_string(resp, encoding = "UTF-8")

    if (cache) {
      dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
      writeLines(txt, path, useBytes = TRUE)
    }
  }

  gho_parse_json(txt)
}

`%||%` <- function(x, y) if (is.null(x)) y else x

#' Search GHO indicator metadata by keyword
#'
#' @param keyword Keyword to search within IndicatorName.
#' @param top_n Maximum number of results.
#' @param offline If `TRUE`, use a pinned fixture (if available) instead of
#'   calling the live API. This is intended for vignettes/tests that must be
#'   deterministic.
#'
#' @return tibble with indicator codes and names.
#' @export
gho_find_indicator <- function(keyword, top_n = 50, offline = FALSE) {
  assert_is_scalar_chr(keyword)

  if (isTRUE(offline)) {
    # Currently we only ship a small fixture for a representative keyword used in
    # vignettes; fall back to live mode for other queries.
    if (identical(tolower(keyword), "measles") && top_n <= 10) {
      path <- system.file(
        "extdata", "fixtures", "gho_Indicator_contains_Measles_top10.json",
        package = "vpdsus"
      )
      if (!identical(path, "")) {
        txt <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
        out <- gho_parse_json(txt)
      } else {
        out <- tibble::tibble()
      }
    } else {
      out <- tibble::tibble()
    }
  } else {
    q <- list(
      `$filter` = sprintf("contains(IndicatorName,'%s')", gsub("'", "''", keyword)),
      `$top` = top_n
    )
    out <- gho_get("Indicator", query = q)
  }

  if (!all(c("IndicatorCode", "IndicatorName") %in% names(out))) {
    return(tibble::tibble(indicator_code = character(), indicator_name = character()))
  }

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
#' `vpdsus` aims to provide conservative defaults that are known to work.
#' Additional indicators can be discovered via [gho_find_indicator()] and passed
#' explicitly to [get_coverage()] / [get_cases()].
#'
#' @return tibble.
#' @export
vpd_indicators <- function() {
  tibble::tibble(
    key = c(
      "mcv1_coverage",
      "mcv2_coverage",
      "dtp3_coverage",
      "pol3_coverage",
      "measles_cases",
      "rubella_cases"
    ),
    type = c("coverage", "coverage", "coverage", "coverage", "cases", "cases"),
    antigen_or_disease = c("MCV1", "MCV2", "DTP3", "POL3", "measles", "rubella"),
    indicator_code = c(
      # Verified via gho_find_indicator()/live API and pinned fixtures/tests.
      "WHS8_110", # MCV1 coverage
      "MCV2",     # MCV2 coverage
      "WHS4_100", # DTP3 coverage
      "WHS4_544", # Polio (Pol3) coverage
      "WHS3_62",  # measles cases
      "WHS3_57"   # rubella cases
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

  out <- gho_standardise_coverage(raw)

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
  out <- gho_standardise_cases(raw)
  if (!is.null(years)) out <- dplyr::filter(out, .data$year %in% years)
  if (!is.null(countries)) out <- dplyr::filter(out, .data$iso3 %in% standardise_iso3(countries))

  dplyr::distinct(out, .data$iso3, .data$year, .keep_all = TRUE)
}
