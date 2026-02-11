test_that("build_panel joins coverage/cases/demography into a vpd_panel", {
  panel0 <- vpdsus_example_panel()

  # minimal inputs
  coverage <- dplyr::transmute(panel0, iso3, year, coverage)
  cases <- dplyr::transmute(panel0, iso3, year, cases)
  demography <- get_demography(source = "example")

  panel <- build_panel(coverage = coverage, cases = cases, demography = demography)

  expect_s3_class(panel, "vpd_panel")
  expect_true(is.data.frame(panel))
  expect_true(all(c("iso3", "year", "coverage", "cases", "pop_total", "births") %in% names(panel)))

  diag <- panel_diagnostics(panel)
  expect_true(is.data.frame(diag))
  expect_true(all(c("n", "missing_coverage", "missing_cases", "missing_pop") %in% names(diag)))
})
