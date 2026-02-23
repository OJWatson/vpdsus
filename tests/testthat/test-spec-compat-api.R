test_that("build_panel_from_sources returns a panel", {
  coverage <- tibble::tibble(iso3 = "USA", year = 2020L, coverage = 0.9)
  cases <- tibble::tibble(iso3 = "USA", year = 2020L, cases = 100)
  demography <- get_demography(source = "fixture_wpp", years = 2020, countries = "USA")
  meta <- utils::read.csv(
    system.file("extdata", "country_metadata_small.csv", package = "vpdsus"),
    stringsAsFactors = FALSE
  )

  p <- build_panel_from_sources(
    years = 2020,
    countries = "USA",
    demography_source = "fixture_wpp",
    coverage = coverage,
    cases = cases,
    demography = demography,
    country_metadata = meta
  )

  expect_s3_class(p, "vpd_panel")
  expect_true(all(c("iso3", "year", "coverage", "cases", "pop_total") %in% names(p)))
})

test_that("summarise_age_groups aggregates fixture data", {
  raw <- utils::read.csv(
    system.file("extdata", "demography_wpp_like_small.csv", package = "vpdsus"),
    stringsAsFactors = FALSE
  )
  s <- summarise_age_groups(raw)
  expect_true(all(c("iso3", "year", "pop_total", "pop_0_4", "pop_5_14") %in% names(s)))
  expect_true(nrow(s) > 0)
})

test_that("estimate_susceptible dispatch works for all methods", {
  panel <- vpdsus_example_panel()

  s1 <- estimate_susceptible(panel, method = "static", coverage_col = "coverage", pop_col = "pop_0_4")
  s2 <- estimate_susceptible(panel, method = "cohort", coverage_col = "coverage", births_col = "births", pop_col = "pop_0_4")
  s3 <- estimate_susceptible(panel, method = "cohort_ve", c1_col = "coverage", c2_col = "coverage", births_col = "births", pop_col = "pop_0_4")
  s4 <- estimate_susceptible(panel, method = "case_balance", rho = 1, coverage_col = "coverage", births_col = "births", cases_col = "cases", pop_col = "pop_total")

  for (s in list(s1, s2, s3, s4)) {
    expect_s3_class(s, "tbl_df")
    expect_true(all(c("iso3", "year", "susceptible_n", "susceptible_prop") %in% names(s)))
  }
})
