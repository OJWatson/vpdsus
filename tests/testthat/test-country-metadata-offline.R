test_that("get_country_metadata() returns expected columns (offline fixture)", {
  skip_if_not_installed("dplyr")

  m <- get_country_metadata(c("afg", "NGA"), offline = TRUE)

  expect_true(all(c("iso3", "country", "who_region", "who_region_name") %in% names(m)))
  expect_true(all(m$iso3 %in% c("AFG", "NGA")))

  af <- dplyr::filter(m, iso3 == "AFG")
  expect_equal(af$country[[1]], "Afghanistan")
  expect_equal(af$who_region[[1]], "EMR")
  expect_equal(af$who_region_name[[1]], "Eastern Mediterranean")
})
