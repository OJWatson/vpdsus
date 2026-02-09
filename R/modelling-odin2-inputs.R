#' Build odin2 input vectors from a year-keyed tibble
#'
#' Convenience helper for preparing `inputs=` for [odin2_simulate()].
#'
#' @param data A data frame/tibble containing a time column (default `year`) and
#'   one or more input columns (e.g. `births`, `vaccinated`, `cases`).
#' @param times Numeric/integer vector of times (typically years) to align to.
#' @param cols Character vector of input column names to extract.
#' @param time_col Name of the time column in `data`.
#' @param iso3 Optional ISO3 code to filter `data` when it contains multiple
#'   countries.
#' @param iso3_col Name of the ISO3 column in `data`.
#'
#' @return Named list of numeric vectors, each of length `length(times)`.
#' @export
odin2_inputs_from_tibble <- function(
    data,
    times,
    cols = c("births", "vaccinated", "cases"),
    time_col = "year",
    iso3 = NULL,
    iso3_col = "iso3") {
  if (!is.data.frame(data)) {
    cli::cli_abort("{.arg data} must be a data.frame")
  }
  if (length(times) == 0) {
    cli::cli_abort("{.arg times} must have length > 0")
  }

  if (!time_col %in% names(data)) {
    cli::cli_abort("{.arg data} is missing time column '{time_col}'")
  }

  if (!is.null(iso3)) {
    if (!iso3_col %in% names(data)) {
      cli::cli_abort("{.arg data} is missing iso3 column '{iso3_col}'")
    }
    data <- data[data[[iso3_col]] == iso3, , drop = FALSE]
  }

  missing_cols <- setdiff(cols, names(data))
  if (length(missing_cols) > 0) {
    cli::cli_abort("{.arg data} is missing input columns: {missing_cols}")
  }

  # Keep only relevant columns and drop duplicate (time, iso3) rows if present.
  keep <- unique(c(time_col, iso3_col, cols))
  keep <- keep[keep %in% names(data)]
  data2 <- data[, keep, drop = FALSE]

  # If iso3 was not provided and iso3 exists, ensure data is single-country.
  if (is.null(iso3) && iso3_col %in% names(data2)) {
    u <- unique(stats::na.omit(data2[[iso3_col]]))
    if (length(u) > 1) {
      cli::cli_abort(
        "{.arg data} contains multiple iso3 values; pass {.arg iso3} to select one"
      )
    }
  }

  # Build mapping from times to rows.
  tchr <- as.character(times)
  data_times <- as.character(data2[[time_col]])

  missing_times <- setdiff(tchr, unique(data_times))
  if (length(missing_times) > 0) {
    cli::cli_abort(
      "{.arg data} does not cover all requested times. Missing: {missing_times}"
    )
  }

  # Select first row for each time (if duplicates exist).
  idx <- match(tchr, data_times)

  out <- purrr::map(cols, function(nm) {
    as.numeric(data2[[nm]][idx])
  })
  names(out) <- cols
  out
}
