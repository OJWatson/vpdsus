test_that("get_country_metadata() returns expected columns (offline fixture)", {
  m <- get_country_metadata(c("afg", "NGA"), offline = TRUE)

  expect_true(is.data.frame(m))
  expect_true(all(c("iso3", "country", "who_region", "who_region_name") %in% names(m)))
  expect_true(all(m$iso3 %in% c("AFG", "NGA")))
  expect_true(nrow(m) == 2)
})
