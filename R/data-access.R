# Internal helpers for building/parsing GHO requests

# Build a stable WHO GHO OData URL from endpoint + query list
# (Used in tests/fixtures; not exported)
gho_build_url <- function(endpoint, query = list()) {
  assert_is_scalar_chr(endpoint)
  base <- gho_base_url()
  url <- paste0(base, "/", endpoint)
  if (length(query)) {
    qs <- paste0(
      utils::URLencode(names(query)),
      "=",
      utils::URLencode(as.character(query)),
      collapse = "&"
    )
    url <- paste0(url, "?", qs)
  }
  url
}

gho_cache_key <- function(endpoint, query = list()) {
  url <- gho_build_url(endpoint, query)
  paste0(gsub("[^A-Za-z0-9]+", "_", endpoint), "_", hash_list(list(url = url)))
}

gho_parse_json <- function(txt) {
  parsed <- jsonlite::fromJSON(txt, simplifyVector = TRUE)
  value <- parsed$value %||% parsed
  tibble::as_tibble(value)
}

gho_parse_number <- function(x) {
  # GHO sometimes returns formatted numbers like "18 617".
  # Strip non-numeric formatting before coercion.
  x <- as.character(x)
  x <- gsub("[^0-9\\.-]", "", x)
  suppressWarnings(as.numeric(x))
}

gho_standardise_coverage <- function(raw) {
  out <- dplyr::transmute(
    raw,
    iso3 = standardise_iso3(.data$SpatialDim %||% .data$SpatialDimValueCode %||% .data$COUNTRY_CODE),
    year = as.integer(.data$TimeDim %||% .data$TimeDimValueCode %||% .data$YEAR),
    coverage = gho_parse_number(.data$Value)
  )
  out <- dplyr::filter(out, !is.na(.data$iso3), !is.na(.data$year))
  dplyr::mutate(out, coverage = dplyr::if_else(.data$coverage > 1, .data$coverage / 100, .data$coverage))
}

gho_standardise_cases <- function(raw) {
  out <- dplyr::transmute(
    raw,
    iso3 = standardise_iso3(.data$SpatialDim %||% .data$SpatialDimValueCode %||% .data$COUNTRY_CODE),
    year = as.integer(.data$TimeDim %||% .data$TimeDimValueCode %||% .data$YEAR),
    cases = gho_parse_number(.data$Value)
  )
  dplyr::filter(out, !is.na(.data$iso3), !is.na(.data$year))
}
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
    # Pinned fixtures for a small set of representative indicator keywords.
    # Keep this list conservative; offline mode is for deterministic tests/vignettes.
    keyword_lower <- tolower(keyword)

    fixture <- NULL
    if (top_n <= 10) {
      fixture <- switch(
        keyword_lower,
        "measles" = "gho_Indicator_contains_Measles_top10.json",
        "dtp3" = "gho_Indicator_contains_DTP3_top10.json",
        "polio" = "gho_Indicator_contains_Polio_top10.json",
        "rubella" = "gho_Indicator_contains_Rubella_top10.json",
        "mcv1" = "gho_Indicator_contains_MCV1_top10.json",
        "mcv2" = "gho_Indicator_contains_MCV2_top10.json",
        "hepb3" = "gho_Indicator_contains_HEPB3_top10.json",
        "hib3" = "gho_Indicator_contains_HIB3_top10.json",
        "pcv3" = "gho_Indicator_contains_PCV3_top10.json",
        "pertussis" = "gho_Indicator_contains_pertussis_top10.json",
        NULL
      )
    }

    if (!is.null(fixture)) {
      path <- system.file("extdata", "fixtures", fixture, package = "vpdsus")
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
      "hepb3_coverage",
      "hib3_coverage",
      "pcv3_coverage",
      "measles_cases",
      "rubella_cases",
      "pertussis_cases"
    ),
    type = c(
      "coverage", "coverage", "coverage", "coverage",
      "coverage", "coverage", "coverage",
      "cases", "cases", "cases"
    ),
    antigen_or_disease = c(
      "MCV1", "MCV2", "DTP3", "POL3",
      "HEPB3", "HIB3", "PCV3",
      "measles", "rubella", "pertussis"
    ),
    indicator_code = c(
      # Verified via gho_find_indicator()/live API and pinned fixtures/tests.
      "WHS8_110", # MCV1 coverage
      "MCV2",     # MCV2 coverage
      "WHS4_100", # DTP3 coverage
      "WHS4_544", # Polio (Pol3) coverage
      "WHS4_117", # HepB3 coverage
      "WHS4_129", # Hib3 coverage
      "PCV3",     # PCV3 coverage
      "WHS3_62",  # measles cases
      "WHS3_57",  # rubella cases
      "WHS3_43"   # pertussis cases
    )
  )
}

#' Measles-related indicator registry (explicit + optional dynamic expansion)
#'
#' @param expand One of `\"explicit\"`, `\"dynamic\"`, or `\"both\"`.
#' @param top_n Maximum number of dynamic matches to request from WHO metadata.
#' @param quiet Logical; passed to [gho_get()] through [gho_find_indicator()].
#'
#' @return tibble with `indicator_code`, `indicator_name`, and `source`.
#' @export
vpd_indicators_measles <- function(expand = c("explicit", "dynamic", "both"), top_n = 500, quiet = TRUE) {
  expand <- match.arg(expand)

  explicit <- tibble::tibble(
    indicator_code = c("WHS8_110", "MCV2", "WHS3_62"),
    indicator_name = c("MCV1 coverage", "MCV2 coverage", "Measles - number of reported cases"),
    source = "explicit"
  )

  dynamic <- tibble::tibble(
    indicator_code = character(),
    indicator_name = character(),
    source = character()
  )

  if (expand %in% c("dynamic", "both")) {
    dynamic <- tryCatch(
      gho_find_indicator("measles", top_n = top_n, offline = FALSE) |>
        dplyr::transmute(
          indicator_code = as.character(.data$indicator_code),
          indicator_name = as.character(.data$indicator_name),
          source = "dynamic"
        ),
      error = function(e) {
        if (!quiet) {
          cli::cli_warn("Dynamic measles indicator discovery failed; returning explicit list only")
        }
        tibble::tibble(
          indicator_code = character(),
          indicator_name = character(),
          source = character()
        )
      }
    )
  }

  out <- dplyr::bind_rows(
    if (expand %in% c("explicit", "both")) explicit else explicit[0, ],
    dynamic
  ) |>
    dplyr::filter(!is.na(.data$indicator_code), .data$indicator_code != "") |>
    dplyr::distinct(.data$indicator_code, .keep_all = TRUE)

  out
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
#' Get country metadata (name, WHO region)
#'
#' Retrieve metadata for countries from the WHO GHO OData dimension values.
#' This is useful for joining human-readable country names and WHO region codes
#' onto country-year panels.
#'
#' By default this function uses the live GHO API (with optional caching via
#' [gho_get()]). For deterministic vignettes/tests you can set `offline = TRUE`
#' to use a small pinned fixture shipped with the package.
#'
#' @param countries Optional ISO3 character vector. If `NULL`, returns metadata
#'   for all available countries.
#' @param cache Logical; passed to [gho_get()].
#' @param quiet Logical; passed to [gho_get()].
#' @param offline Logical; if `TRUE`, use a pinned fixture instead of calling the
#'   live API.
#'
#' @return A tibble with columns:
#'   - `iso3`: ISO3 country code
#'   - `country`: country name
#'   - `who_region`: WHO region code (e.g. "AFR")
#'   - `who_region_name`: WHO region name (e.g. "Africa")
#' @export
get_country_metadata <- function(
    countries = NULL,
    cache = TRUE,
    quiet = TRUE,
    offline = FALSE) {
  if (!is.null(countries)) {
    countries <- standardise_iso3(countries)
  }

  if (isTRUE(offline)) {
    out <- country_metadata_offline_fixture()
  } else {
    # Dimension values: Code (ISO3), Title (country name), ParentCode/Title (region)
    raw <- gho_get(
      "Dimension/COUNTRY/DimensionValues",
      query = list(`$top` = 10000),
      cache = cache,
      quiet = quiet
    )

    out <- tibble::as_tibble(raw) |>
      dplyr::transmute(
        iso3 = standardise_iso3(.data$Code),
        country = as.character(.data$Title),
        who_region = as.character(.data$ParentCode),
        who_region_name = as.character(.data$ParentTitle)
      ) |>
      dplyr::filter(!is.na(.data$iso3), nchar(.data$iso3) == 3)
  }

  out <- dplyr::distinct(out, .data$iso3, .keep_all = TRUE)

  if (!is.null(countries)) {
    out <- dplyr::filter(out, .data$iso3 %in% countries)
  }

  out
}

# Small deterministic fixture used in tests/vignettes
#
# Columns: iso3,country,who_region,who_region_name
#
# @keywords internal
# @noRd
country_metadata_offline_fixture <- function() {
  path <- system.file("extdata", "country_metadata_small.csv", package = "vpdsus")
  if (identical(path, "")) {
    cli::cli_abort("Could not find country metadata fixture file in inst/extdata")
  }

  df <- utils::read.csv(path, stringsAsFactors = FALSE)
  out <- tibble::as_tibble(df) |>
    dplyr::transmute(
      iso3 = standardise_iso3(.data$iso3),
      country = as.character(.data$country),
      who_region = as.character(.data$who_region),
      who_region_name = as.character(.data$who_region_name)
    ) |>
    dplyr::filter(!is.na(.data$iso3), nchar(.data$iso3) == 3)

  dplyr::distinct(out, .data$iso3, .keep_all = TRUE)
}

#' Get conflict exposure series (country-year)
#'
#' Returns conflict exposure indicators aligned to `iso3` + `year`. The default
#' source is a shipped UCDP annual fixture for deterministic analysis.
#'
#' @param years Optional integer vector.
#' @param countries Optional ISO3 vector.
#' @param source One of `"ucdp_fixture"` (default) or `"wb_battle_deaths"`.
#' @param indicator_code World Bank indicator code used when
#'   `source = "wb_battle_deaths"`. Default is `"VC.BTL.DETH"` (battle-related
#'   deaths, number of people).
#' @param cache Logical; cache live World Bank pulls.
#' @param quiet Logical.
#'
#' @return tibble with columns:
#'   - `iso3`, `year`
#'   - `conflict_events_total`
#'   - `conflict_fatalities_best`
#'   - `conflict_any_event` (discrete indicator)
#' @export
get_conflict <- function(
    years = NULL,
    countries = NULL,
    source = c("ucdp_fixture", "wb_battle_deaths"),
    indicator_code = "VC.BTL.DETH",
    cache = TRUE,
    quiet = TRUE) {
  source <- match.arg(source)

  if (source == "ucdp_fixture") {
    p <- system.file("extdata", "conflict_ucdp_annual_v251.csv", package = "vpdsus")
    if (!nzchar(p)) {
      cli::cli_abort("Could not find shipped conflict fixture file in inst/extdata")
    }
    out <- tibble::as_tibble(utils::read.csv(p, stringsAsFactors = FALSE)) |>
      dplyr::transmute(
        iso3 = standardise_iso3(.data$iso3),
        year = as.integer(.data$year),
        conflict_events_total = as.numeric(.data$conflict_events_total),
        conflict_fatalities_best = as.numeric(.data$conflict_fatalities_best),
        conflict_any_event = as.integer(.data$conflict_any_event)
      ) |>
      dplyr::distinct(.data$iso3, .data$year, .keep_all = TRUE)
  } else {
    key <- paste0(
      "wb_conflict_",
      gsub("[^A-Za-z0-9]+", "_", indicator_code),
      "_",
      hash_list(list(years = sort(unique(years)), countries = sort(unique(countries))))
    )
    path <- cache_paths(key, ext = "json")
    if (cache && file.exists(path)) {
      txt <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
      parsed <- jsonlite::fromJSON(txt, simplifyVector = TRUE)
    } else {
      url <- sprintf(
        "https://api.worldbank.org/v2/country/all/indicator/%s?format=json&per_page=20000",
        utils::URLencode(indicator_code, reserved = TRUE)
      )
      if (!quiet) cli::cli_inform("Downloading {url}")
      resp <- httr2::request(url) |>
        httr2::req_user_agent("vpdsus (https://github.com/OJWatson/vpdsus)") |>
        httr2::req_retry(max_tries = 3) |>
        httr2::req_perform()
      txt <- httr2::resp_body_string(resp, encoding = "UTF-8")
      parsed <- jsonlite::fromJSON(txt, simplifyVector = TRUE)
      if (cache) {
        dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
        writeLines(txt, path, useBytes = TRUE)
      }
    }
    d <- parsed[[2]]
    if (is.null(d) || NROW(d) == 0) {
      out <- tibble::tibble(
        iso3 = character(),
        year = integer(),
        conflict_events_total = numeric(),
        conflict_fatalities_best = numeric(),
        conflict_any_event = integer()
      )
    } else {
      out <- tibble::as_tibble(d) |>
        dplyr::transmute(
          iso3 = standardise_iso3(.data$countryiso3code),
          year = as.integer(.data$date),
          conflict_events_total = as.numeric(.data$value),
          conflict_fatalities_best = as.numeric(.data$value),
          conflict_any_event = as.integer(as.numeric(.data$value) > 0)
        ) |>
        dplyr::filter(!is.na(.data$iso3), nchar(.data$iso3) == 3, !is.na(.data$year)) |>
        dplyr::distinct(.data$iso3, .data$year, .keep_all = TRUE)
    }
  }

  if (!is.null(years)) out <- dplyr::filter(out, .data$year %in% as.integer(years))
  if (!is.null(countries)) out <- dplyr::filter(out, .data$iso3 %in% standardise_iso3(countries))
  out
}

#' Merge conflict indicators onto a country-year panel
#'
#' @param panel A panel data.frame/tibble with at least `iso3`, `year`, and `pop_total`.
#' @param conflict Output of [get_conflict()].
#'
#' @return Panel with added conflict columns:
#'   `conflict_events_total`, `conflict_fatalities_best`, `conflict_any_event`,
#'   `conflict_data_available`, `conflict_fatalities_per_100k`,
#'   `conflict_fatalities_log1p`.
#' @export
merge_conflict_with_panel <- function(panel, conflict) {
  assert_has_cols(panel, c("iso3", "year", "pop_total"), "panel")
  assert_has_cols(conflict, c("iso3", "year", "conflict_fatalities_best"), "conflict")

  p <- tibble::as_tibble(panel) |>
    dplyr::mutate(
      iso3 = standardise_iso3(.data$iso3),
      year = as.integer(.data$year),
      pop_total = as.numeric(.data$pop_total)
    )
  c <- tibble::as_tibble(conflict) |>
    dplyr::mutate(
      iso3 = standardise_iso3(.data$iso3),
      year = as.integer(.data$year),
      conflict_events_total = as.numeric(.data$conflict_events_total),
      conflict_fatalities_best = as.numeric(.data$conflict_fatalities_best),
      conflict_any_event = as.integer(.data$conflict_any_event)
    )

  y0 <- min(c$year, na.rm = TRUE)
  y1 <- max(c$year, na.rm = TRUE)

  out <- dplyr::left_join(p, c, by = c("iso3", "year")) |>
    dplyr::mutate(
      conflict_data_available = .data$year >= y0 & .data$year <= y1,
      conflict_events_total = dplyr::if_else(.data$conflict_data_available & is.na(.data$conflict_events_total), 0, .data$conflict_events_total),
      conflict_fatalities_best = dplyr::if_else(.data$conflict_data_available & is.na(.data$conflict_fatalities_best), 0, .data$conflict_fatalities_best),
      conflict_any_event = dplyr::if_else(.data$conflict_data_available & is.na(.data$conflict_any_event), 0L, .data$conflict_any_event),
      conflict_fatalities_per_100k = dplyr::if_else(
        !is.na(.data$conflict_fatalities_best) & .data$pop_total > 0,
        .data$conflict_fatalities_best / .data$pop_total * 1e5,
        NA_real_
      ),
      conflict_fatalities_log1p = dplyr::if_else(!is.na(.data$conflict_fatalities_best), log1p(.data$conflict_fatalities_best), NA_real_)
    )

  out
}
