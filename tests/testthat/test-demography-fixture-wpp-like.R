test_that("get_demography(source='fixture_wpp') returns expected columns", {
  d <- get_demography(source = "fixture_wpp", years = 2020, countries = "USA")

  expect_true(is.data.frame(d))
  expect_true(all(c("iso3", "year", "pop_total", "pop_0_4", "pop_5_14", "births") %in% names(d)))
  expect_equal(unique(d$iso3), "USA")
  expect_equal(unique(d$year), 2020L)
  expect_true(all(d$pop_total > 0))
  expect_true(all(d$births > 0))
  expect_true(all(d$pop_0_4 <= d$pop_total))
})

test_that("get_demography() standardises ISO3 inputs", {
  d <- get_demography(source = "fixture_wpp", years = 2020, countries = c("usa", " Usa "))

  expect_equal(unique(d$iso3), "USA")
  expect_equal(unique(d$year), 2020L)
})
