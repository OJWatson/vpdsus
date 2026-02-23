#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(purrr)
  library(tibble)
  library(httr2)
  library(jsonlite)
})

out_panel <- "inst/extdata/example_panel_measles_global.csv"
out_long <- "inst/extdata/measles_indicators_global_long.csv"
out_prov <- "inst/extdata/example_panel_measles_global.PROVENANCE.md"

base_gho <- "https://ghoapi.azureedge.net/api"

parse_num <- function(x) {
  x <- as.character(x)
  x <- gsub("[^0-9\\.-]", "", x)
  suppressWarnings(as.numeric(x))
}

standardise_iso3 <- function(x) {
  x <- toupper(trimws(as.character(x)))
  x[nchar(x) != 3] <- NA_character_
  x
}

gho_get <- function(endpoint, query = list()) {
  url <- paste0(base_gho, "/", endpoint)
  req <- request(url) |>
    req_user_agent("vpdsus-data-builder") |>
    req_retry(max_tries = 3)
  if (length(query) > 0) {
    req <- do.call(req_url_query, c(list(.req = req), query))
  }
  resp <- req_perform(req)
  txt <- resp_body_string(resp, encoding = "UTF-8")
  val <- fromJSON(txt, simplifyVector = TRUE)$value
  as_tibble(val)
}

message("Discovering measles-related indicators...")
ind <- gho_get(
  "Indicator",
  query = list(
    `$filter` = "contains(IndicatorName,'measles')",
    `$top` = 500
  )
) |>
  transmute(
    indicator_code = as.character(.data$IndicatorCode),
    indicator_name = as.character(.data$IndicatorName)
  ) |>
  filter(!is.na(.data$indicator_code), .data$indicator_code != "") |>
  distinct(.data$indicator_code, .keep_all = TRUE)

# Explicitly include core measles workflow indicators.
core_add <- tibble(
  indicator_code = c("WHS8_110", "MCV2", "WHS3_62"),
  indicator_name = c("MCV1 coverage", "MCV2 coverage", "Measles - number of reported cases")
)
ind <- bind_rows(ind, core_add) |>
  distinct(.data$indicator_code, .keep_all = TRUE)

message("Found ", nrow(ind), " indicators")

fetch_indicator_series <- function(code, nm) {
  message("  pulling ", code)
  dat <- tryCatch(
    gho_get(code),
    error = function(e) NULL
  )
  if (is.null(dat) || nrow(dat) == 0) {
    return(tibble())
  }
  out <- dat |>
    transmute(
      iso3 = standardise_iso3(.data$SpatialDim %||% .data$SpatialDimValueCode %||% .data$COUNTRY_CODE),
      year = as.integer(.data$TimeDim %||% .data$TimeDimValueCode %||% .data$YEAR),
      value = parse_num(.data$Value)
    ) |>
    filter(!is.na(.data$iso3), !is.na(.data$year), !is.na(.data$value)) |>
    mutate(indicator_code = code, indicator_name = nm)
  out
}

`%||%` <- function(x, y) if (is.null(x)) y else x

long <- map2_dfr(ind$indicator_code, ind$indicator_name, fetch_indicator_series) |>
  distinct(.data$iso3, .data$year, .data$indicator_code, .keep_all = TRUE)

# Build wide indicator frame
nm_safe <- function(x) {
  x <- tolower(x)
  x <- gsub("[^a-z0-9]+", "_", x)
  x <- gsub("_+", "_", x)
  x <- gsub("^_|_$", "", x)
  x
}

col_or_na <- function(df, nm) {
  if (nm %in% names(df)) {
    df[[nm]]
  } else {
    rep(NA_real_, nrow(df))
  }
}

wide <- long |>
  mutate(ind_col = paste0("ind_", nm_safe(.data$indicator_code))) |>
  select("iso3", "year", "ind_col", "value") |>
  pivot_wider(names_from = .data$ind_col, values_from = .data$value)

# Core compatibility columns
core <- wide
core$coverage <- dplyr::coalesce(col_or_na(core, "ind_whs8_110"), col_or_na(core, "ind_mcv1"))
core$mcv2 <- col_or_na(core, "ind_mcv2")
core$cases <- dplyr::coalesce(col_or_na(core, "ind_whs3_62"), col_or_na(core, "ind_measles"))

# World Bank demography helpers
wb_get <- function(indicator) {
  message("  pulling WB ", indicator)
  u <- sprintf(
    "https://api.worldbank.org/v2/country/all/indicator/%s?format=json&per_page=20000",
    indicator
  )
  x <- fromJSON(u, simplifyVector = TRUE)
  if (length(x) < 2 || is.null(x[[2]])) return(tibble())
  as_tibble(x[[2]]) |>
    transmute(
      iso3 = standardise_iso3(.data$countryiso3code),
      year = as.integer(.data$date),
      value = as.numeric(.data$value)
    ) |>
    filter(!is.na(.data$iso3), !is.na(.data$year))
}

message("Pulling world-scale demography from World Bank...")
pop_total <- wb_get("SP.POP.TOTL") |>
  rename(pop_total = "value")
pct_0_14 <- wb_get("SP.POP.0014.TO.ZS") |>
  rename(pct_0_14 = "value")
cbirth <- wb_get("SP.DYN.CBRT.IN") |>
  rename(cbr = "value")

demog <- reduce(
  list(pop_total, pct_0_14, cbirth),
  ~full_join(.x, .y, by = c("iso3", "year"))
) |>
  mutate(
    # Approximate split of 0-14 into 0-4 and 5-14 when only 0-14 share is available.
    pop_0_4 = .data$pop_total * .data$pct_0_14 / 100 * (5 / 15),
    pop_5_14 = .data$pop_total * .data$pct_0_14 / 100 * (10 / 15),
    births = .data$pop_total * .data$cbr / 1000
  ) |>
  select(.data$iso3, .data$year, .data$pop_total, .data$pop_0_4, .data$pop_5_14, .data$births)

message("Pulling country metadata from World Bank...")
wb_meta <- fromJSON("https://api.worldbank.org/v2/country?format=json&per_page=400", simplifyVector = TRUE)
meta_raw <- as_tibble(wb_meta[[2]])
meta <- tibble(
  iso3 = standardise_iso3(meta_raw$id),
  country = as.character(meta_raw$name),
  who_region = as.character(meta_raw$region$id),
  who_region_name = as.character(meta_raw$region$value)
) |>
  filter(!is.na(.data$iso3), .data$who_region != "NA") |>
  distinct(.data$iso3, .keep_all = TRUE)

panel <- full_join(core, demog, by = c("iso3", "year")) |>
  left_join(meta, by = "iso3") |>
  mutate(
    coverage = if_else(!is.na(.data$coverage) & .data$coverage > 1, .data$coverage / 100, .data$coverage),
    year = as.integer(.data$year)
  ) |>
  filter(!is.na(.data$iso3), !is.na(.data$year)) |>
  arrange(.data$iso3, .data$year)

dir.create(dirname(out_panel), recursive = TRUE, showWarnings = FALSE)
write.csv(panel, out_panel, row.names = FALSE, na = "")
write.csv(long, out_long, row.names = FALSE, na = "")

prov <- c(
  "# Global measles example panel provenance",
  "",
  paste0("Generated at (UTC): ", format(Sys.time(), tz = "UTC", usetz = TRUE)),
  "",
  "## Sources",
  "- WHO GHO OData API: measles-related indicators (dynamic discovery: contains(IndicatorName, 'measles'))",
  "- WHO GHO OData API: explicit core indicators WHS8_110 (MCV1), MCV2, WHS3_62 (measles cases)",
  "- World Bank API countries endpoint for country + region metadata",
  "- World Bank API indicators: SP.POP.TOTL, SP.POP.0014.TO.ZS, SP.DYN.CBRT.IN",
  "",
  "## Counts",
  paste0("- Indicators discovered: ", nrow(ind)),
  paste0("- Long rows: ", nrow(long)),
  paste0("- Panel rows: ", nrow(panel)),
  paste0("- Countries: ", dplyr::n_distinct(panel$iso3)),
  paste0("- Year range: ", min(panel$year, na.rm = TRUE), " to ", max(panel$year, na.rm = TRUE))
)
writeLines(prov, out_prov)

message("Wrote:")
message(" - ", out_panel)
message(" - ", out_long)
message(" - ", out_prov)
