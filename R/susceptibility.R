#' Method A: static coverage-based susceptibility
#'
#' @param panel A [vpd_panel] or tibble.
#' @param coverage_col Name of coverage column (proportion 0-1).
#' @param pop_col Population column for the age group of interest.
#' @param age_group Label for returned age_group column.
#' @param ve Vaccine efficacy (default 1).
#'
#' @return tibble with iso3, year, age_group, susceptible_n, susceptible_prop, method.
#' @export
estimate_susceptible_static <- function(panel,
                                       coverage_col = "coverage",
                                       pop_col = "pop_0_4",
                                       age_group = "0-4",
                                       ve = 1) {
  assert_has_cols(panel, c("iso3", "year", coverage_col, pop_col))

  cov <- panel[[coverage_col]]
  pop <- panel[[pop_col]]

  eff <- pmin(pmax(as.numeric(cov) * ve, 0), 1)
  prop <- 1 - eff
  out <- tibble::tibble(
    iso3 = standardise_iso3(panel$iso3),
    year = as.integer(panel$year),
    age_group = age_group,
    susceptible_prop = prop,
    susceptible_n = prop * as.numeric(pop),
    method = "static",
    assumptions = list(list(ve = ve, coverage_col = coverage_col, pop_col = pop_col))
  )
  out
}

#' Method B: cohort reconstruction using births + coverage
#'
#' @param panel A [vpd_panel] or tibble with iso3, year, births, pop_0_4, and coverage.
#' @param years_back Integer; number of years in the age group window (default 4 for 0-4).
#' @param coverage_col Coverage column.
#' @param births_col Births column.
#' @param pop_col Population denominator column.
#' @param age_group Label.
#'
#' @return tibble.
#' @export
estimate_susceptible_cohort <- function(panel,
                                       years_back = 4,
                                       coverage_col = "coverage",
                                       births_col = "births",
                                       pop_col = "pop_0_4",
                                       age_group = "0-4") {
  assert_has_cols(panel, c("iso3", "year", coverage_col, births_col, pop_col))

  df <- tibble::as_tibble(panel) |>
    dplyr::mutate(
      iso3 = standardise_iso3(.data$iso3),
      year = as.integer(.data$year),
      coverage = as.numeric(.data[[coverage_col]]),
      births = as.numeric(.data[[births_col]]),
      pop = as.numeric(.data[[pop_col]]),
      cov_eff = pmin(pmax(.data$coverage, 0), 1)
    ) |>
    dplyr::arrange(.data$iso3, .data$year)

  # Cohort susceptibility contribution for birth year c evaluated at year y uses coverage in c
  births_by_cohort <- dplyr::select(df, .data$iso3, cohort_year = .data$year, births = .data$births, cov_eff = .data$cov_eff)

  out <- df |>
    dplyr::group_by(.data$iso3) |>
    dplyr::group_modify(function(dat, key) {
      # For each year y, sum cohorts y, y-1, ..., y-years_back
      ys <- dat$year
      susc <- vapply(seq_along(ys), function(i) {
        y <- ys[[i]]
        cohorts <- y - (0:years_back)
        tmp <- dplyr::filter(births_by_cohort, .data$iso3 == key$iso3, .data$cohort_year %in% cohorts)
        sum(tmp$births * (1 - tmp$cov_eff), na.rm = TRUE)
      }, numeric(1))
      tibble::tibble(
        year = ys,
        susceptible_n = susc,
        pop = dat$pop
      )
    }) |>
    dplyr::ungroup() |>
    dplyr::mutate(
      age_group = age_group,
      susceptible_prop = .data$susceptible_n / .data$pop,
      method = "cohort",
      assumptions = list(list(years_back = years_back, coverage_col = coverage_col, births_col = births_col, pop_col = pop_col))
    ) |>
    dplyr::select(.data$iso3, .data$year, .data$age_group, .data$susceptible_n, .data$susceptible_prop, .data$method, .data$assumptions)

  out
}

#' Method C: cohort reconstruction with two doses + vaccine efficacy
#'
#' @param panel Panel with coverage columns for dose1 and dose2.
#' @param c1_col Coverage for dose 1.
#' @param c2_col Coverage for dose 2.
#' @param ve1 Vaccine efficacy for dose 1.
#' @param ve2 Vaccine efficacy for dose 2.
#' @inheritParams estimate_susceptible_cohort
#'
#' @export
estimate_susceptible_cohort_ve <- function(panel,
                                          years_back = 4,
                                          c1_col = "mcv1",
                                          c2_col = "mcv2",
                                          births_col = "births",
                                          pop_col = "pop_0_4",
                                          age_group = "0-4",
                                          ve1 = 0.93,
                                          ve2 = 0.97) {
  assert_has_cols(panel, c("iso3", "year", c1_col, c2_col, births_col, pop_col))

  df <- tibble::as_tibble(panel) |>
    dplyr::mutate(
      iso3 = standardise_iso3(.data$iso3),
      year = as.integer(.data$year),
      c1 = pmin(pmax(as.numeric(.data[[c1_col]]), 0), 1),
      c2 = pmin(pmax(as.numeric(.data[[c2_col]]), 0), 1),
      births = as.numeric(.data[[births_col]]),
      pop = as.numeric(.data[[pop_col]])
    )

  p_protected <- 1 - (1 - df$c1 * ve1) * (1 - df$c2 * ve2)
  df$cov_eff <- pmin(pmax(p_protected, 0), 1)

  births_by_cohort <- dplyr::select(df, .data$iso3, cohort_year = .data$year, births = .data$births, cov_eff = .data$cov_eff)

  out <- df |>
    dplyr::arrange(.data$iso3, .data$year) |>
    dplyr::group_by(.data$iso3) |>
    dplyr::group_modify(function(dat, key) {
      ys <- dat$year
      susc <- vapply(seq_along(ys), function(i) {
        y <- ys[[i]]
        cohorts <- y - (0:years_back)
        tmp <- dplyr::filter(births_by_cohort, .data$iso3 == key$iso3, .data$cohort_year %in% cohorts)
        sum(tmp$births * (1 - tmp$cov_eff), na.rm = TRUE)
      }, numeric(1))
      tibble::tibble(year = ys, susceptible_n = susc, pop = dat$pop)
    }) |>
    dplyr::ungroup() |>
    dplyr::mutate(
      age_group = age_group,
      susceptible_prop = .data$susceptible_n / .data$pop,
      method = "cohort_ve",
      assumptions = list(list(years_back = years_back, c1_col = c1_col, c2_col = c2_col, ve1 = ve1, ve2 = ve2))
    ) |>
    dplyr::select(.data$iso3, .data$year, .data$age_group, .data$susceptible_n, .data$susceptible_prop, .data$method, .data$assumptions)

  out
}

#' Method D: susceptible balance updated using cases
#'
#' @param panel Panel with births, coverage, and cases.
#' @param rho Reporting fraction (scalar or vector).
#' @param coverage_col Name of coverage column.
#' @param births_col Name of births column.
#' @param cases_col Name of reported cases column.
#' @param pop_col Name of population column used for proportions.
#' @param age_group Label for returned age_group column.
#' @param s0 Optional initial susceptible count (defaults to births in first year).
#'
#' @return tibble with one row per iso3-year-rho.
#' @export
estimate_susceptible_case_balance <- function(panel,
                                             rho = c(0.05, 0.1, 0.2, 0.5, 1),
                                             coverage_col = "coverage",
                                             births_col = "births",
                                             cases_col = "cases",
                                             pop_col = "pop_total",
                                             age_group = "total",
                                             s0 = NULL) {
  assert_has_cols(panel, c("iso3", "year", coverage_col, births_col, cases_col, pop_col))

  df <- tibble::as_tibble(panel) |>
    dplyr::mutate(
      iso3 = standardise_iso3(.data$iso3),
      year = as.integer(.data$year),
      births = as.numeric(.data[[births_col]]),
      cov = pmin(pmax(as.numeric(.data[[coverage_col]]), 0), 1),
      cases = pmax(as.numeric(.data[[cases_col]]), 0),
      pop = as.numeric(.data[[pop_col]]),
      vaccinated = .data$births * .data$cov
    ) |>
    dplyr::arrange(.data$iso3, .data$year)

  rho <- as.numeric(rho)

  out <- purrr::map_dfr(rho, function(r) {
    df |>
      dplyr::group_by(.data$iso3) |>
      dplyr::group_modify(function(dat, key) {
        n <- nrow(dat)
        S <- numeric(n)
        S[[1]] <- if (is.null(s0)) dat$births[[1]] else s0
        if (n > 1) {
          for (i in 1:(n - 1)) {
            inf_i <- dat$cases[[i]] / r
            S[[i + 1]] <- max(0, S[[i]] + dat$births[[i]] - dat$vaccinated[[i]] - inf_i)
          }
        }
        tibble::tibble(year = dat$year, susceptible_n = S, pop = dat$pop)
      }) |>
      dplyr::ungroup() |>
      dplyr::mutate(
        rho = r,
        age_group = age_group,
        susceptible_prop = .data$susceptible_n / .data$pop,
        method = "case_balance",
        assumptions = list(list(rho = r, coverage_col = coverage_col, births_col = births_col, cases_col = cases_col))
      )
  })

  dplyr::select(out, .data$iso3, .data$year, .data$age_group, .data$rho,
                .data$susceptible_n, .data$susceptible_prop, .data$method, .data$assumptions)
}
