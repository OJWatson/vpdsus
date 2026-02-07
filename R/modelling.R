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
      who_region = as.factor(.data$who_region),
      year = as.numeric(.data$year)
    )

  m1 <- stats::glm(outcome ~ susceptible_prop + year + who_region, data = data, family = stats::binomial())

  coefs <- tibble::as_tibble(summary(m1)$coefficients, rownames = "term") |>
    dplyr::rename(estimate = Estimate, std_error = `Std. Error`, statistic = `z value`, p_value = `Pr(>|z|)`)

  list(model = m1, coefficients = coefs)
}

#' Time-aware model evaluation (simple split)
#'
#' @param data Modelling panel.
#' @param train_end Last year included in training.
#'
#' @return tibble with accuracy and Brier score.
#' @export
evaluate_models <- function(data, train_end = NULL) {
  assert_has_cols(data, c("year", "outcome", "susceptible_prop", "who_region"))
  if (is.null(train_end)) train_end <- stats::quantile(data$year, probs = 0.7, na.rm = TRUE)

  train <- dplyr::filter(data, .data$year <= train_end)
  test <- dplyr::filter(data, .data$year > train_end)

  fit <- fit_outbreak_models(train)$model
  p <- stats::predict(fit, newdata = test, type = "response")
  y <- test$outcome

  pred <- as.integer(p >= 0.5)
  acc <- mean(pred == y)
  brier <- mean((p - y)^2)

  tibble::tibble(
    train_end = train_end,
    n_train = nrow(train),
    n_test = nrow(test),
    accuracy = acc,
    brier = brier
  )
}
