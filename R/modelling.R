#' Make outbreak outcome variables from cases
#'
#' @param cases Numeric vector.
#' @param pop Numeric vector.
#' @param abs_threshold Absolute case count threshold.
#' @param pc_threshold Per-100k threshold.
#'
#' @return tibble with outbreak definitions.
#' @export
make_outcome_outbreak <- function(cases, pop, abs_threshold = 1000, pc_threshold = 10) {
  cases <- as.numeric(cases)
  pop <- as.numeric(pop)
  pc <- (cases / pop) * 1e5

  tibble::tibble(
    outbreak_abs = as.integer(cases >= abs_threshold),
    outbreak_pc = as.integer(pc >= pc_threshold),
    cases_per_100k = pc
  )
}

#' Create lagged modelling panel
#'
#' @param panel A [vpd_panel] including cases and population.
#' @param suscept Susceptibility tibble (iso3, year, susceptible_prop, susceptible_n).
#' @param outcome Which outbreak outcome to use.
#' @param lag_years Predictor lag in years.
#'
#' @return tibble.
#' @export
make_modelling_panel <- function(panel, suscept, outcome = c("outbreak_pc", "outbreak_abs"), lag_years = 1) {
  outcome <- match.arg(outcome)
  assert_has_cols(panel, c("iso3", "year", "cases", "pop_total"))
  assert_has_cols(suscept, c("iso3", "year", "susceptible_prop"))

  panel <- tibble::as_tibble(panel) |>
    dplyr::mutate(iso3 = standardise_iso3(.data$iso3), year = as.integer(.data$year))
  suscept <- tibble::as_tibble(suscept) |>
    dplyr::mutate(iso3 = standardise_iso3(.data$iso3), year = as.integer(.data$year))

  outc <- make_outcome_outbreak(panel$cases, panel$pop_total)
  panel2 <- dplyr::bind_cols(panel, outc)

  df <- dplyr::left_join(panel2, suscept, by = c("iso3", "year")) |>
    dplyr::arrange(.data$iso3, .data$year) |>
    dplyr::group_by(.data$iso3) |>
    dplyr::mutate(
      outcome_next = dplyr::lead(.data[[outcome]], n = lag_years),
      cases_next = dplyr::lead(.data$cases, n = lag_years),
      year_next = .data$year + lag_years
    ) |>
    dplyr::ungroup() |>
    dplyr::filter(!is.na(.data$outcome_next), !is.na(.data$susceptible_prop))

  dplyr::transmute(
    df,
    iso3,
    year,
    year_next,
    outcome = .data$outcome_next,
    susceptible_prop,
    susceptible_n = .data$susceptible_n %||% NA_real_,
    cases = .data$cases,
    cases_next,
    cases_per_100k = .data$cases_per_100k,
    pop_total = .data$pop_total,
    who_region = .data$who_region %||% NA_character_
  )
}

#' Fit baseline outbreak models
#'
#' @param data A modelling panel from [make_modelling_panel()].
#'
#' @return List with model and tidy coefficients.
#' @export
fit_outbreak_models <- function(data) {
  assert_has_cols(data, c("outcome", "susceptible_prop", "year", "who_region"))

  data <- tibble::as_tibble(data) |>
    dplyr::mutate(
      who_region = as.factor(dplyr::coalesce(as.character(.data$who_region), "UNK")),
      year = as.numeric(.data$year)
    )

  m1 <- stats::glm(outcome ~ susceptible_prop + year + who_region, data = data, family = stats::binomial())

  coefs <- tibble::as_tibble(summary(m1)$coefficients, rownames = "term") |>
    dplyr::rename(estimate = Estimate, std_error = `Std. Error`, statistic = `z value`, p_value = `Pr(>|z|)`)

  list(model = m1, coefficients = coefs)
}

#' Time-aware model evaluation (simple split)
#'
#' `evaluate_models()` is a convenience wrapper around
#' [evaluate_outbreak_time_split()] that returns a single-row tibble of summary
#' metrics.
#'
#' @param data Modelling panel.
#' @param train_end Last year included in training.
#'
#' @return Single-row tibble with evaluation metrics.
#' @export
evaluate_models <- function(data, train_end = NULL) {
  evaluate_outbreak_time_split(data, train_end = train_end)$metrics
}

roc_auc_binary <- function(y, p) {
  # AUC via Mann–Whitney (rank) statistic; deterministic and dependency-light.
  y <- as.integer(y)
  if (!all(y %in% c(0L, 1L))) {
    cli::cli_abort("y must be binary (0/1)")
  }
  n_pos <- sum(y == 1L)
  n_neg <- sum(y == 0L)
  if (n_pos == 0L || n_neg == 0L) {
    return(NA_real_)
  }
  r <- rank(p, ties.method = "average")
  u <- sum(r[y == 1L]) - (n_pos * (n_pos + 1) / 2)
  as.numeric(u / (n_pos * n_neg))
}

#' Time-aware outbreak model evaluation with plots
#'
#' Fits the baseline outbreak model on an early-year training set and evaluates
#' it on later years.
#'
#' @param data Modelling panel from [make_modelling_panel()].
#' @param train_end Last year included in training. If `NULL`, chooses a cutoff
#'   that holds out at least one distinct year.
#' @param threshold Classification threshold for `pred_outbreak`.
#' @param n_bins Number of bins for the calibration plot.
#'
#' @return List with components `metrics` (single-row tibble), `predictions`
#'   (test-set tibble with probabilities), and `plots` (ggplot objects).
#' @export
evaluate_outbreak_time_split <- function(data, train_end = NULL, threshold = 0.5, n_bins = 10) {
  assert_has_cols(data, c("year", "year_next", "outcome", "susceptible_prop", "who_region"))

  years <- sort(unique(stats::na.omit(as.numeric(data$year))))
  if (length(years) < 2) {
    cli::cli_abort("Need at least 2 distinct years to evaluate models")
  }

  if (is.null(train_end)) {
    idx <- max(1, floor(0.7 * length(years)))
    idx <- min(idx, length(years) - 1)
    train_end <- years[[idx]]
  }

  train <- dplyr::filter(data, .data$year <= train_end)
  test <- dplyr::filter(data, .data$year > train_end)

  if (nrow(test) == 0) {
    metrics0 <- tibble::tibble(
      train_end = train_end,
      n_train = nrow(train),
      n_test = 0L,
      prevalence = NA_real_,
      accuracy = NA_real_,
      brier = NA_real_,
      log_loss = NA_real_,
      auc = NA_real_
    )
    return(list(metrics = metrics0, predictions = tibble::tibble(), plots = list(time = NULL, calibration = NULL)))
  }

  fit <- fit_outbreak_models(train)$model

  who_levels <- fit$xlevels$who_region %||% NULL
  test2 <- tibble::as_tibble(test) |>
    dplyr::mutate(
      year = as.numeric(.data$year),
      who_region_chr = dplyr::coalesce(as.character(.data$who_region), "UNK"),
      who_region_chr = if (is.null(who_levels)) {
        .data$who_region_chr
      } else {
        dplyr::if_else(.data$who_region_chr %in% who_levels, .data$who_region_chr, "UNK")
      },
      who_region = if (is.null(who_levels)) {
        as.factor(.data$who_region_chr)
      } else {
        factor(.data$who_region_chr, levels = union(who_levels, "UNK"))
      }
    )

  p <- suppressWarnings(stats::predict(fit, newdata = test2, type = "response"))
  y <- as.integer(test2$outcome)

  pred <- as.integer(p >= threshold)
  acc <- mean(pred == y)
  brier <- mean((p - y)^2)
  eps <- 1e-15
  p2 <- pmin(pmax(p, eps), 1 - eps)
  log_loss <- -mean(y * log(p2) + (1 - y) * log(1 - p2))
  auc <- roc_auc_binary(y, p)

  metrics <- tibble::tibble(
    train_end = train_end,
    n_train = nrow(train),
    n_test = nrow(test2),
    prevalence = mean(y),
    accuracy = acc,
    brier = brier,
    log_loss = log_loss,
    auc = auc
  )

  preds <- dplyr::mutate(
    test2,
    prob_outbreak = as.numeric(p),
    pred_outbreak = pred
  )

  plot_time <- plot_outbreak_predictions_time(preds)
  plot_cal <- plot_outbreak_calibration(preds, n_bins = n_bins)

  list(metrics = metrics, predictions = preds, plots = list(time = plot_time, calibration = plot_cal))
}

#' Plot observed vs predicted outbreak probability over time
#'
#' @param predictions A data frame as returned by `evaluate_outbreak_time_split()$predictions`.
#'
#' @return A ggplot.
#' @export
plot_outbreak_predictions_time <- function(predictions) {
  assert_has_cols(predictions, c("year_next", "outcome", "prob_outbreak"))

  df <- tibble::as_tibble(predictions) |>
    dplyr::mutate(year_next = as.integer(.data$year_next)) |>
    dplyr::group_by(.data$year_next) |>
    dplyr::summarise(
      n = dplyr::n(),
      observed = mean(.data$outcome),
      predicted = mean(.data$prob_outbreak),
      .groups = "drop"
    )

  ggplot2::ggplot(df, ggplot2::aes(x = .data$year_next)) +
    ggplot2::geom_line(ggplot2::aes(y = .data$observed, colour = "Observed")) +
    ggplot2::geom_point(ggplot2::aes(y = .data$observed, colour = "Observed")) +
    ggplot2::geom_line(ggplot2::aes(y = .data$predicted, colour = "Predicted")) +
    ggplot2::geom_point(ggplot2::aes(y = .data$predicted, colour = "Predicted")) +
    ggplot2::scale_colour_manual(values = c(Observed = "black", Predicted = "#3366CC")) +
    ggplot2::scale_y_continuous(labels = scales::label_percent(accuracy = 1)) +
    ggplot2::labs(x = "Outcome year", y = "Outbreak probability", colour = NULL)
}

#' Calibration plot (binned)
#'
#' @param predictions A data frame as returned by `evaluate_outbreak_time_split()$predictions`.
#' @param n_bins Number of probability bins.
#'
#' @return A ggplot.
#' @export
plot_outbreak_calibration <- function(predictions, n_bins = 10) {
  assert_has_cols(predictions, c("outcome", "prob_outbreak"))

  df <- tibble::as_tibble(predictions) |>
    dplyr::mutate(
      bin = dplyr::ntile(.data$prob_outbreak, n_bins)
    ) |>
    dplyr::group_by(.data$bin) |>
    dplyr::summarise(
      n = dplyr::n(),
      p_hat = mean(.data$prob_outbreak),
      observed = mean(.data$outcome),
      .groups = "drop"
    )

  ggplot2::ggplot(df, ggplot2::aes(x = .data$p_hat, y = .data$observed)) +
    ggplot2::geom_abline(intercept = 0, slope = 1, linetype = 2, colour = "grey50") +
    ggplot2::geom_point(ggplot2::aes(size = .data$n)) +
    ggplot2::geom_line() +
    ggplot2::scale_size_continuous(range = c(1.5, 5)) +
    ggplot2::scale_x_continuous(limits = c(0, 1), labels = scales::label_percent(accuracy = 1)) +
    ggplot2::scale_y_continuous(limits = c(0, 1), labels = scales::label_percent(accuracy = 1)) +
    ggplot2::labs(x = "Mean predicted probability", y = "Observed outbreak rate", size = "N")
}
