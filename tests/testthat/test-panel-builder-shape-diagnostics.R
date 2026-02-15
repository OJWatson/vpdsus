test_that("build_panel returns full key union and is sorted", {
  coverage <- tibble::tibble(
    iso3 = c("bwa", "usa"),
    year = c(2001L, 2000L),
    coverage = c(0.8, 0.9)
  )

  cases <- tibble::tibble(
    iso3 = c("USA", "USA"),
    year = c(2000L, 2001L),
    cases = c(10, 11)
  )

  demography <- tibble::tibble(
    iso3 = c("USA", "BWA"),
    year = c(2001L, 2001L),
    pop_total = c(1e6, 2e6),
    pop_0_4 = c(1e5, 2e5),
    pop_5_14 = c(2e5, 3e5),
    births = c(2e4, 3e4)
  )

  panel <- build_panel(coverage = coverage, cases = cases, demography = demography)

  # union of keys across all inputs = (BWA,2001) + (USA,2000) + (USA,2001)
  expect_equal(nrow(panel), 3)
  expect_equal(dplyr::distinct(panel, iso3, year) |> nrow(), 3)

  # build_panel standardises iso3 and sorts
  expect_equal(panel$iso3, sort(panel$iso3, method = "radix"))
  expect_true(all(diff(panel$year[panel$iso3 == "USA"]) >= 0))

  # ensure class sticks even after tibble conversion upstream
  expect_s3_class(panel, "vpd_panel")
})

test_that("panel_diagnostics reports correct missingness counts", {
  coverage <- tibble::tibble(
    iso3 = c("USA"),
    year = c(2000L),
    coverage = c(0.9)
  )

  cases <- tibble::tibble(
    iso3 = c("USA"),
    year = c(2001L),
    cases = c(11)
  )

  demography <- tibble::tibble(
    iso3 = c("USA"),
    year = c(2000L),
    pop_total = c(1e6),
    pop_0_4 = c(1e5),
    pop_5_14 = c(2e5),
    births = c(2e4)
  )

  panel <- build_panel(coverage = coverage, cases = cases, demography = demography)
  diag <- panel_diagnostics(panel)

  expect_equal(nrow(diag), 1)
  expect_equal(diag$n, 2) # rows: (USA,2000) and (USA,2001)
  expect_equal(diag$missing_coverage, 1) # year 2001 missing coverage
  expect_equal(diag$missing_cases, 1) # year 2000 missing cases
  expect_equal(diag$missing_pop, 1) # year 2001 missing demography
})

test_that("build_panel rejects duplicated keys in inputs", {
  demography <- get_demography(source = "example") |> dplyr::slice(1:5)

  coverage <- tibble::tibble(
    iso3 = c("USA", "USA"),
    year = c(2000L, 2000L),
    coverage = c(0.9, 0.91)
  )

  cases <- tibble::tibble(
    iso3 = c("USA"),
    year = c(2000L),
    cases = c(10)
  )

  expect_error(
    build_panel(coverage = coverage, cases = cases, demography = demography),
    "duplicated key rows",
    fixed = TRUE
  )
})
