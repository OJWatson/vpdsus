#' Compute risk categories and ranking tables
#'
#' @param panel A [vpd_panel] including at least iso3, year, who_region (optional), coverage.
#' @param suscept Output from an estimation function (Method A/B/etc).
#' @param window_years Integer; rolling window for coverage mean.
#' @param year_end Optional; year to rank at (defaults to max year available).
#' @param breaks Coverage breakpoints for risk categories.
#'
#' @return A tibble with ranking columns and class 'vpdsus_rank'.
#' @export
risk_rank <- function(panel, suscept, window_years = 15, year_end = NULL,
                      breaks = c(0, 0.5, 0.7, 0.85, 1)) {
  assert_has_cols(panel, c("iso3", "year", "coverage"))
  assert_has_cols(suscept, c("iso3", "year", "susceptible_n", "susceptible_prop"))

  panel <- tibble::as_tibble(panel) |>
    dplyr::mutate(iso3 = standardise_iso3(.data$iso3), year = as.integer(.data$year))
  suscept <- tibble::as_tibble(suscept) |>
    dplyr::mutate(iso3 = standardise_iso3(.data$iso3), year = as.integer(.data$year))

  if (is.null(year_end)) year_end <- max(panel$year, na.rm = TRUE)
  year_start <- year_end - window_years + 1

  cov_sum <- panel |>
    dplyr::filter(.data$year >= year_start, .data$year <= year_end) |>
    dplyr::group_by(.data$iso3) |>
    dplyr::summarise(
      coverage_mean = mean(.data$coverage, na.rm = TRUE),
      who_region = dplyr::first(.data$who_region %||% NA_character_),
      country = dplyr::first(.data$country %||% .data$iso3),
      .groups = "drop"
    )

  susc_y <- suscept |>
    dplyr::filter(.data$year == year_end) |>
    dplyr::group_by(.data$iso3) |>
    dplyr::summarise(
      susceptible_n = dplyr::first(.data$susceptible_n),
      susceptible_prop = dplyr::first(.data$susceptible_prop),
      method = dplyr::first(.data$method),
      .groups = "drop"
    )

  out <- dplyr::left_join(cov_sum, susc_y, by = "iso3") |>
    dplyr::mutate(
      risk_category = cut(
        .data$coverage_mean,
        breaks = breaks,
        include.lowest = TRUE,
        labels = c("very_high", "high", "medium", "low")
      ),
      rank_global = dplyr::min_rank(dplyr::desc(.data$susceptible_n))
    ) |>
    dplyr::arrange(.data$rank_global)

  class(out) <- c("vpdsus_rank", class(out))
  attr(out, "year_end") <- year_end
  attr(out, "year_start") <- year_start
  out
}

vpdsus_theme <- function() {
  ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      legend.position = "bottom"
    )
}

#' WHO-style coverage ranking plot
#'
#' @param rank_tbl Output of [risk_rank()].
#' @param top_n Number of countries to show.
#' @export
plot_coverage_rank <- function(rank_tbl, top_n = 30) {
  year_end <- attr(rank_tbl, "year_end") %||% NA

  df <- tibble::as_tibble(rank_tbl) |>
    dplyr::slice_head(n = top_n) |>
    dplyr::mutate(country = factor(.data$country, levels = rev(.data$country)))

  ggplot2::ggplot(df, ggplot2::aes(x = .data$coverage_mean, y = .data$country, fill = .data$risk_category)) +
    ggplot2::geom_col(width = 0.8, colour = "grey30") +
    ggplot2::scale_x_continuous(labels = scales::percent_format(accuracy = 1)) +
    ggplot2::labs(
      x = sprintf("Mean coverage (%s-year window, ending %s)", attr(rank_tbl, "year_end") %||% "", year_end),
      y = NULL,
      fill = "Risk category",
      title = "Coverage ranking"
    ) +
    vpdsus_theme()
}

#' WHO-style susceptible ranking plot
#'
#' @param rank_tbl Output of [risk_rank()].
#' @param top_n Number of countries.
#' @export
plot_susceptible_rank <- function(rank_tbl, top_n = 30) {
  df <- tibble::as_tibble(rank_tbl) |>
    dplyr::slice_head(n = top_n) |>
    dplyr::mutate(country = factor(.data$country, levels = rev(.data$country)))

  ggplot2::ggplot(df, ggplot2::aes(x = .data$susceptible_n, y = .data$country, fill = .data$risk_category)) +
    ggplot2::geom_col(width = 0.8, colour = "grey30") +
    ggplot2::scale_x_continuous(labels = scales::comma) +
    ggplot2::labs(
      x = "Estimated susceptible population (n)",
      y = NULL,
      fill = "Risk category",
      title = "Susceptible population ranking"
    ) +
    vpdsus_theme()
}

#' Panel missingness diagnostic plot
#'
#' @param panel A [vpd_panel].
#' @export
plot_panel_diagnostics <- function(panel) {
  assert_has_cols(panel, c("iso3", "year"))
  df <- tibble::as_tibble(panel) |>
    dplyr::mutate(
      missing_coverage = is.na(.data$coverage),
      missing_cases = is.na(.data$cases),
      missing_pop = is.na(.data$pop_total)
    ) |>
    tidyr::pivot_longer(dplyr::starts_with("missing_"), names_to = "variable", values_to = "missing")

  ggplot2::ggplot(df, ggplot2::aes(x = .data$year, y = .data$iso3, fill = .data$missing)) +
    ggplot2::geom_tile() +
    ggplot2::scale_fill_manual(values = c(`TRUE` = "tomato", `FALSE` = "grey80")) +
    ggplot2::labs(x = NULL, y = NULL, fill = "Missing", title = "Panel missingness") +
    vpdsus_theme()
}
