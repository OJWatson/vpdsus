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
