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
vpdsus_cache_dir <- function(create = TRUE) {
  dir <- tools::R_user_dir("vpdsus", which = "cache")
  if (create && !dir.exists(dir)) dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  dir
}

vpdsus_clear_cache <- function() {
  dir <- vpdsus_cache_dir(create = FALSE)
  if (dir.exists(dir)) unlink(dir, recursive = TRUE, force = TRUE)
  invisible(TRUE)
}

#' Cache information
#'
#' @return A tibble with cache directory, number of files, and total size.
#' @export
vpdsus_cache_info <- function() {
  dir <- vpdsus_cache_dir(create = FALSE)
  files <- if (dir.exists(dir)) list.files(dir, recursive = TRUE, full.names = TRUE) else character()
  tibble::tibble(
    cache_dir = dir,
    n_files = length(files),
    bytes = if (length(files)) sum(file.info(files)$size, na.rm = TRUE) else 0
  )
}

hash_list <- function(x) {
  # Small, deterministic hash without extra deps.
  # tools::md5sum() works on files, so write to a temp file.
  raw <- paste(utils::capture.output(str(x)), collapse = "\n")
  f <- tempfile(fileext = ".txt")
  on.exit(unlink(f), add = TRUE)
  writeLines(raw, f, useBytes = TRUE)
  unname(as.character(tools::md5sum(f)))
}

cache_paths <- function(key, ext = "json") {
  dir <- file.path(vpdsus_cache_dir(), "gho")
  if (!dir.exists(dir)) dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  file.path(dir, paste0(key, ".", ext))
}

cache_paths_demography <- function(key, ext = "rds") {
  dir <- file.path(vpdsus_cache_dir(), "demography")
  if (!dir.exists(dir)) dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  file.path(dir, paste0(key, ".", ext))
}
#' Internal imports
#'
#' @name vpdsus-internal
#' @keywords internal
#' @importFrom utils capture.output read.csv str
NULL
