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
    coverage = .data$coverage,
    susceptible_prop,
    susceptible_n = .data$susceptible_n %||% NA_real_,
    cases = .data$cases,
    cases_next,
    cases_per_100k = .data$cases_per_100k,
    pop_total = .data$pop_total,
    who_region = .data$who_region %||% NA_character_
  )
}

#' Create lagged modelling panel with conflict predictors
#'
#' Builds a country-year modelling table with:
#' - binary next-year outbreak outcome,
#' - next-year changes in cases and coverage,
#' - discrete + continuous conflict exposure indicators.
#'
#' @param panel A panel containing outbreak inputs and conflict columns.
#' @param lag_years Predictor lag in years.
#' @param outcome Which outbreak outcome to use.
#' @param require_conflict_available If `TRUE`, keep only years in conflict-data coverage window.
#'
#' @return tibble.
#' @export
make_conflict_modelling_panel <- function(
    panel,
    lag_years = 1,
    outcome = c("outbreak_pc", "outbreak_abs"),
    require_conflict_available = TRUE) {
  outcome <- match.arg(outcome)
  assert_has_cols(
    panel,
    c(
      "iso3", "year", "cases", "coverage", "pop_total", "who_region",
      "conflict_any_event", "conflict_fatalities_per_100k", "conflict_data_available"
    )
  )

  df <- tibble::as_tibble(panel) |>
    dplyr::mutate(
      iso3 = standardise_iso3(.data$iso3),
      year = as.integer(.data$year),
      cases = as.numeric(.data$cases),
      coverage = as.numeric(.data$coverage),
      pop_total = as.numeric(.data$pop_total),
      conflict_any_event = as.numeric(.data$conflict_any_event),
      conflict_fatalities_per_100k = as.numeric(.data$conflict_fatalities_per_100k),
      conflict_data_available = as.logical(.data$conflict_data_available)
    ) |>
    dplyr::arrange(.data$iso3, .data$year)

  outc <- make_outcome_outbreak(df$cases, df$pop_total)
  df2 <- dplyr::bind_cols(df, outc) |>
    dplyr::group_by(.data$iso3) |>
    dplyr::mutate(
      outcome_next = dplyr::lead(.data[[outcome]], n = lag_years),
      cases_next = dplyr::lead(.data$cases, n = lag_years),
      coverage_next = dplyr::lead(.data$coverage, n = lag_years),
      year_next = .data$year + lag_years,
      delta_log_cases = log1p(.data$cases_next) - log1p(.data$cases),
      delta_coverage = .data$coverage_next - .data$coverage
    ) |>
    dplyr::ungroup() |>
    dplyr::filter(!is.na(.data$outcome_next))

  if (isTRUE(require_conflict_available)) {
    df2 <- dplyr::filter(df2, .data$conflict_data_available)
  }

  dplyr::transmute(
    df2,
    iso3 = .data$iso3,
    year = .data$year,
    year_next = .data$year_next,
    who_region = .data$who_region,
    outcome = .data$outcome_next,
    cases = .data$cases,
    cases_next = .data$cases_next,
    coverage = .data$coverage,
    coverage_next = .data$coverage_next,
    delta_log_cases = .data$delta_log_cases,
    delta_coverage = .data$delta_coverage,
    conflict_any_event = .data$conflict_any_event,
    conflict_fatalities_per_100k = .data$conflict_fatalities_per_100k
  )
}

coef_table <- function(mod, model_name) {
  if (is.null(mod)) {
    return(tibble::tibble(
      model = character(),
      term = character(),
      estimate = numeric(),
      std_error = numeric(),
      statistic = numeric(),
      p_value = numeric()
    ))
  }
  ctab <- tibble::as_tibble(summary(mod)$coefficients, rownames = "term")
  z_col <- if ("z value" %in% names(ctab)) "z value" else NA_character_
  t_col <- if ("t value" %in% names(ctab)) "t value" else NA_character_
  pz_col <- if ("Pr(>|z|)" %in% names(ctab)) "Pr(>|z|)" else NA_character_
  pt_col <- if ("Pr(>|t|)" %in% names(ctab)) "Pr(>|t|)" else NA_character_

  ctab |>
    dplyr::rename(estimate = Estimate, std_error = `Std. Error`) |>
    dplyr::mutate(
      statistic = dplyr::coalesce(
        if (!is.na(z_col)) .data[[z_col]] else NA_real_,
        if (!is.na(t_col)) .data[[t_col]] else NA_real_
      ),
      p_value = dplyr::coalesce(
        if (!is.na(pz_col)) .data[[pz_col]] else NA_real_,
        if (!is.na(pt_col)) .data[[pt_col]] else NA_real_
      ),
      model = model_name
    ) |>
    dplyr::select(.data$model, .data$term, .data$estimate, .data$std_error, .data$statistic, .data$p_value)
}

#' Fit conflict-effect models for outbreaks and changes
#'
#' @param data Output of [make_conflict_modelling_panel()].
#'
#' @return List containing fitted models and combined coefficient table.
#' @export
fit_conflict_effect_models <- function(data) {
  assert_has_cols(
    data,
    c(
      "outcome", "delta_coverage", "delta_log_cases", "coverage", "year",
      "who_region", "conflict_any_event", "conflict_fatalities_per_100k"
    )
  )

  d <- tibble::as_tibble(data) |>
    dplyr::mutate(
      year = as.numeric(.data$year),
      who_region = as.factor(dplyr::coalesce(as.character(.data$who_region), "UNK"))
    )

  m_outbreak <- stats::glm(
    outcome ~ conflict_any_event + conflict_fatalities_per_100k + coverage + year + who_region,
    data = d, family = stats::binomial()
  )
  m_cov <- stats::lm(
    delta_coverage ~ conflict_any_event + conflict_fatalities_per_100k + coverage + year + who_region,
    data = d
  )
  m_cases <- stats::lm(
    delta_log_cases ~ conflict_any_event + conflict_fatalities_per_100k + coverage + year + who_region,
    data = d
  )

  list(
    model_outbreak = m_outbreak,
    model_delta_coverage = m_cov,
    model_delta_cases = m_cases,
    coefficients = dplyr::bind_rows(
      coef_table(m_outbreak, "outbreak_logit"),
      coef_table(m_cov, "delta_coverage_lm"),
      coef_table(m_cases, "delta_log_cases_lm")
    )
  )
}

#' Fit baseline outbreak models
#'
#' @param data A modelling panel from [make_modelling_panel()].
#'
#' @return List containing logistic and negative-binomial model fits and tidy coefficients.
#' @export
fit_outbreak_models <- function(data) {
  assert_has_cols(data, c("outcome", "susceptible_prop", "year", "who_region", "cases_next"))

  data <- tibble::as_tibble(data) |>
    dplyr::mutate(
      who_region = as.factor(dplyr::coalesce(as.character(.data$who_region), "UNK")),
      year = as.numeric(.data$year)
    )

  m1 <- stats::glm(outcome ~ susceptible_prop + year + who_region, data = data, family = stats::binomial())

  coefs <- tibble::as_tibble(summary(m1)$coefficients, rownames = "term") |>
    dplyr::rename(estimate = Estimate, std_error = `Std. Error`, statistic = `z value`, p_value = `Pr(>|z|)`)

  # Negative binomial model for next-year case counts.
  m_nb <- tryCatch(
    MASS::glm.nb(cases_next ~ susceptible_prop + year + who_region, data = data),
    error = function(e) NULL
  )
  coefs_nb <- if (is.null(m_nb)) {
    tibble::tibble(term = character(), estimate = numeric(), std_error = numeric(), statistic = numeric(), p_value = numeric())
  } else {
    tibble::as_tibble(summary(m_nb)$coefficients, rownames = "term") |>
      dplyr::rename(estimate = Estimate, std_error = `Std. Error`, statistic = `z value`, p_value = `Pr(>|z|)`)
  }

  list(
    model = m1,
    coefficients = coefs,
    model_nb = m_nb,
    coefficients_nb = coefs_nb
  )
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

#' Rolling-origin outbreak model evaluation
#'
#' Evaluates the baseline model across multiple time cutoffs.
#'
#' @param data Modelling panel from [make_modelling_panel()].
#' @param min_train_years Minimum number of distinct years to include in training.
#' @param threshold Classification threshold for predicted outbreak.
#' @param n_bins Number of bins used for calibration plots in each split.
#'
#' @return Tibble with one row per rolling split and summary metrics.
#' @export
evaluate_models_rolling_origin <- function(data, min_train_years = 2, threshold = 0.5, n_bins = 10) {
  years <- sort(unique(stats::na.omit(as.numeric(data$year))))
  if (length(years) < (min_train_years + 1)) {
    cli::cli_abort("Need at least {min_train_years + 1} distinct years for rolling-origin evaluation")
  }

  cutoffs <- years[min_train_years:(length(years) - 1)]
  purrr::map_dfr(cutoffs, function(cutoff) {
    m <- evaluate_outbreak_time_split(
      data = data,
      train_end = cutoff,
      threshold = threshold,
      n_bins = n_bins
    )$metrics
    dplyr::mutate(m, split_type = "rolling_origin")
  })
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
