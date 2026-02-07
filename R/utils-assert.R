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

standardise_iso3 <- function(x) {
  toupper(trimws(as.character(x)))
}
