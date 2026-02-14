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
