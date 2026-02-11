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

gho_standardise_coverage <- function(raw) {
  out <- dplyr::transmute(
    raw,
    iso3 = standardise_iso3(.data$SpatialDim %||% .data$SpatialDimValueCode %||% .data$COUNTRY_CODE),
    year = as.integer(.data$TimeDim %||% .data$TimeDimValueCode %||% .data$YEAR),
    coverage = as.numeric(.data$Value)
  )
  out <- dplyr::filter(out, !is.na(.data$iso3), !is.na(.data$year))
  dplyr::mutate(out, coverage = dplyr::if_else(.data$coverage > 1, .data$coverage / 100, .data$coverage))
}

gho_standardise_cases <- function(raw) {
  out <- dplyr::transmute(
    raw,
    iso3 = standardise_iso3(.data$SpatialDim %||% .data$SpatialDimValueCode %||% .data$COUNTRY_CODE),
    year = as.integer(.data$TimeDim %||% .data$TimeDimValueCode %||% .data$YEAR),
    cases = as.numeric(.data$Value)
  )
  dplyr::filter(out, !is.na(.data$iso3), !is.na(.data$year))
}
