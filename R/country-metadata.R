#' Get country metadata (name, WHO region)
#'
#' Retrieve metadata for countries from the WHO GHO OData *dimension values*.
#' This is useful for joining human-readable country names and WHO region codes
#' onto country-year panels.
#'
#' By default this function uses the live API (with caching via [gho_get()]).
#' For deterministic vignettes/tests, you can set `offline = TRUE` to use a
#' pinned fixture (when available).
#'
#' @param countries Optional ISO3 character vector. If `NULL`, returns metadata
#'   for all available countries.
#' @param cache Logical; passed to [gho_get()].
#' @param quiet Logical; passed to [gho_get()].
#' @param offline Logical; if `TRUE`, attempt to use a pinned fixture instead of
#'   the live API.
#'
#' @return A tibble with columns:
#'   - `iso3`: ISO3 country code
#'   - `country`: country name
#'   - `who_region`: WHO region code (e.g. "AFR")
#'   - `who_region_name`: WHO region name (e.g. "Africa")
#'
#' @export
get_country_metadata <- function(countries = NULL, cache = TRUE, quiet = TRUE, offline = FALSE) {
  if (!is.null(countries)) {
    countries <- standardise_iso3(countries)
  }

  if (isTRUE(offline)) {
    # Pinned fixture includes a small subset of countries used in example data.
    path <- system.file(
      "extdata", "fixtures", "gho_DIMENSION_COUNTRY_DimensionValues_subset.json",
      package = "vpdsus"
    )

    if (!identical(path, "")) {
      txt <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
      raw <- gho_parse_json(txt)
    } else {
      raw <- tibble::tibble()
    }

    reg_path <- system.file(
      "extdata", "fixtures", "gho_DIMENSION_REGION_DimensionValues_who6.json",
      package = "vpdsus"
    )
    if (!identical(reg_path, "")) {
      txt2 <- paste(readLines(reg_path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
      regions <- gho_parse_json(txt2)
    } else {
      regions <- tibble::tibble()
    }
  } else {
    q <- list(`$select` = "Code,Title,ParentCode,ParentDimension,Dimension")
    if (!is.null(countries)) {
      # OData filter: Code eq 'AFG' or Code eq 'NGA' ...
      # (Avoid 'in' for compatibility)
      clauses <- sprintf("Code eq '%s'", gsub("'", "''", countries))
      q$`$filter` <- paste(clauses, collapse = " or ")
    }

    raw <- gho_get("DIMENSION/COUNTRY/DimensionValues", query = q, cache = cache, quiet = quiet)

    regions <- gho_get(
      "DIMENSION/REGION/DimensionValues",
      query = list(`$select` = "Code,Title"),
      cache = cache,
      quiet = quiet
    )
  }

  if (!all(c("Code", "Title") %in% names(raw))) {
    return(tibble::tibble(
      iso3 = character(),
      country = character(),
      who_region = character(),
      who_region_name = character()
    ))
  }

  out <- dplyr::transmute(
    raw,
    iso3 = standardise_iso3(.data$Code),
    country = as.character(.data$Title),
    who_region = as.character(.data$ParentCode)
  )

  # Prefer WHO's 6 main regions when mapping names (AFR/AMR/EMR/EUR/SEAR/WPR)
  regions2 <- tibble::as_tibble(regions)
  if (all(c("Code", "Title") %in% names(regions2))) {
    regions2 <- dplyr::transmute(
      regions2,
      who_region = as.character(.data$Code),
      who_region_name = as.character(.data$Title)
    )
    out <- dplyr::left_join(out, regions2, by = "who_region")
  } else {
    out$who_region_name <- NA_character_
  }

  out <- dplyr::filter(out, !is.na(.data$iso3))
  out <- dplyr::distinct(out, .data$iso3, .keep_all = TRUE)

  if (!is.null(countries)) {
    out <- dplyr::filter(out, .data$iso3 %in% countries)
  }

  out
}
