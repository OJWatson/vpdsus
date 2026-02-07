#' Compile an odin2 template
#'
#' @param model One of 'balance' or 'sir'.
#' @param file Optional path to a custom template.
#'
#' @return A compiled odin2 model object.
#' @export
odin2_build_model <- function(model = c("balance", "sir"), file = NULL) {
  model <- match.arg(model)
  if (!requireNamespace("odin2", quietly = TRUE)) {
    cli::cli_abort("{.pkg odin2} is required for mechanistic modelling. Install from r-universe as documented in the vignette.")
  }

  if (is.null(file)) {
    file <- switch(
      model,
      balance = system.file("odin", "susceptible_balance.R", package = "vpdsus"),
      sir = system.file("odin", "sir_basic.R", package = "vpdsus")
    )
  }
  if (!nzchar(file) || !file.exists(file)) {
    cli::cli_abort("odin2 template file not found: {file}")
  }

  # source returns compiled model in object 'model'
  env <- new.env(parent = baseenv())
  sys.source(file, envir = env)
  # Expect last value to be odin2 model object; be forgiving
  objs <- mget(ls(env), env)
  mdl <- objs[[length(objs)]]
  mdl
}

#' Simulate an odin2 model
#'
#' @param model Compiled model from [odin2_build_model()].
#' @param times Numeric vector.
#' @param pars Named list.
#' @param initial Named list.
#' @param inputs Optional named list of input vectors (for difference-equation models).
#'
#' @return tibble.
#' @export
odin2_simulate <- function(model, times, pars = list(), initial = list(), inputs = NULL) {
  if (!requireNamespace("odin2", quietly = TRUE)) {
    cli::cli_abort("{.pkg odin2} is required for mechanistic modelling.")
  }

  # odin2 model objects are callable; this is a minimal scaffold.
  inst <- do.call(model, c(initial, pars))
  if (!is.null(inputs)) {
    for (nm in names(inputs)) {
      inst$set_user(nm, inputs[[nm]])
    }
  }
  res <- inst$run(times)
  tibble::as_tibble(res)
}

#' Compare susceptibility trajectories across methods
#'
#' @param panel A panel with iso3/year.
#' @param estimates Named list of susceptibility tibbles.
#' @param iso3 Country ISO3.
#' @export
compare_methods <- function(panel, estimates, iso3) {
  assert_is_scalar_chr(iso3)
  df <- purrr::imap_dfr(estimates, function(x, nm) {
    tibble::as_tibble(x) |>
      dplyr::filter(.data$iso3 == standardise_iso3(iso3)) |>
      dplyr::mutate(method = nm)
  })

  ggplot2::ggplot(df, ggplot2::aes(x = .data$year, y = .data$susceptible_prop, colour = .data$method)) +
    ggplot2::geom_line() +
    ggplot2::scale_y_continuous(labels = scales::percent_format()) +
    ggplot2::labs(x = NULL, y = "Susceptible proportion", title = paste("Susceptibility trajectories:", iso3)) +
    vpdsus_theme()
}
