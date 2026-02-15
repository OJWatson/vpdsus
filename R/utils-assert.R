assert_has_cols <- function(x, cols, name = deparse(substitute(x))) {
  missing <- setdiff(cols, names(x))
  if (length(missing)) {
    cli::cli_abort("{.var {name}} is missing required columns: {missing}")
  }
  invisible(TRUE)
}

assert_is_scalar_chr <- function(x, name = deparse(substitute(x))) {
  if (!(is.character(x) && length(x) == 1 && !is.na(x))) {
    cli::cli_abort("{.var {name}} must be a length-1 character value")
  }
  invisible(TRUE)
}

assert_unique_key <- function(x, key_cols, name = deparse(substitute(x))) {
  assert_has_cols(x, key_cols, name = name)
  dupes <- x |>
    dplyr::count(dplyr::across(dplyr::all_of(key_cols)), name = "n") |>
    dplyr::filter(.data$n > 1)

  if (nrow(dupes) > 0) {
    examples <- utils::head(
      utils::capture.output(print(dupes, n = 10)),
      10
    )

    cli::cli_abort(c(
      "{.var {name}} contains duplicated key rows for {key_cols}.",
      "Example duplicates:",
      "{examples}"
    ))
  }

  invisible(TRUE)
}

standardise_iso3 <- function(x) {
  toupper(trimws(as.character(x)))
}
