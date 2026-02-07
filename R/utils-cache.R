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
  # Small, deterministic hash without extra deps
  raw <- paste(capture.output(str(x)), collapse = "\n")
  as.character(tools::md5sum(textConnection(raw)))
}

cache_paths <- function(key, ext = "json") {
  dir <- file.path(vpdsus_cache_dir(), "gho")
  if (!dir.exists(dir)) dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  file.path(dir, paste0(key, ".", ext))
}
