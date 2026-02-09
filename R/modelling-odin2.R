#' Compile an odin2 template
#'
#' @param model One of 'balance', 'balance_discrete', 'sir', or 'minimal_discrete'.
#' @param file Optional path to a custom template.
#'
#' @return A compiled odin2 model object.
#' @export
odin2_build_model <- function(model = c("balance", "balance_discrete", "sir", "minimal_discrete"), file = NULL) {
  model <- match.arg(model)
  if (!requireNamespace("odin2", quietly = TRUE)) {
    cli::cli_abort("{.pkg odin2} is required for mechanistic modelling. Install from r-universe as documented in the vignette.")
  }

  if (is.null(file)) {
    file <- switch(
      model,
      balance = system.file("odin", "susceptible_balance.R", package = "vpdsus"),
      balance_discrete = system.file("odin", "susceptible_balance_discrete.R", package = "vpdsus"),
      sir = system.file("odin", "sir_basic.R", package = "vpdsus"),
      minimal_discrete = system.file("odin", "minimal_discrete.R", package = "vpdsus")
    )
  }
  if (!nzchar(file) || !file.exists(file)) {
    cli::cli_abort("odin2 template file not found: {file}")
  }

  # Source template; convention is to assign the generator to `model`.
  env <- new.env(parent = baseenv())
  sys.source(file, envir = env)

  if (exists("model", envir = env, inherits = FALSE)) {
    return(get("model", envir = env, inherits = FALSE))
  }

  # Fallback: last object in env
  nms <- ls(env)
  if (length(nms) == 0) {
    cli::cli_abort("odin2 template did not create any objects: {file}")
  }
  objs <- mget(nms, env)
  objs[[length(objs)]]
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

  if (!requireNamespace("dust2", quietly = TRUE)) {
    cli::cli_abort("{.pkg dust2} is required to simulate odin2 models.")
  }

  # odin2::odin() returns a dust_system_generator.
  # Create a system and simulate over requested times.
  sys <- dust2::dust_system_create(model, pars = pars, time = min(times))

  # Set initial state (odin2 discrete-time systems do not allow initial() to
  # depend on parameters, so we set state explicitly here).
  if (length(initial) > 0) {
    st <- unlist(initial, use.names = TRUE)
    dust2::dust_system_set_state(sys, st)
  }

  state_names <- sys$packer_state$names()

  # Helper: extract state as a named numeric vector
  get_state <- function() {
    st <- dust2::dust_system_state(sys)
    names(st) <- state_names
    st
  }

  # No inputs -> fast path
  if (is.null(inputs)) {
    sim <- dust2::dust_system_simulate(sys, times)
    out <- tibble::tibble(time = times)
    for (i in seq_along(state_names)) {
      out[[state_names[[i]]]] <- as.numeric(sim[i, ])
    }
    return(out)
  }

  # Time-varying inputs: update parameters stepwise.
  # Inputs can be:
  #   - scalars (recycled)
  #   - vectors aligned to `times`
  #   - named vectors whose names match `times` (e.g. years)
  inputs2 <- inputs
  for (nm in names(inputs2)) {
    x <- inputs2[[nm]]
    if (length(x) == 1) {
      inputs2[[nm]] <- rep(x, length(times))
    } else if (!is.null(names(x)) && all(as.character(times) %in% names(x))) {
      inputs2[[nm]] <- as.numeric(x[as.character(times)])
    } else if (length(x) == length(times)) {
      inputs2[[nm]] <- as.numeric(x)
    } else {
      cli::cli_abort(
        "Input '{nm}' must be length 1, length(times) ({length(times)}), or a named vector covering all times"
      )
    }
  }

  out <- tibble::tibble(time = times)
  for (nm in state_names) {
    out[[nm]] <- NA_real_
  }

  # Record initial state at times[1]
  st <- get_state()
  for (nm in state_names) {
    out[[nm]][[1]] <- st[[nm]]
  }

  if (length(times) == 1) {
    return(out)
  }

  for (i in 2:length(times)) {
    pars_step <- purrr::map_dbl(inputs2, ~ .x[[i]])
    dust2::dust_system_update_pars(sys, as.list(pars_step))
    dust2::dust_system_run_to_time(sys, times[[i]])

    st <- get_state()
    for (nm in state_names) {
      out[[nm]][[i]] <- st[[nm]]
    }
  }

  out
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
