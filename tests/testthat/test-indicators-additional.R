test_that("vpd_indicators includes verified additional indicator mappings (coverage + cases)", {
  map <- vpd_indicators()

  expect_true(is.data.frame(map))
  expect_true(all(c("key", "type", "antigen_or_disease", "indicator_code") %in% names(map)))

  # Coverage
  expect_true(any(map$key == "dtp3_coverage" & map$indicator_code == "WHS4_100"))
  expect_true(any(map$key == "pol3_coverage" & map$indicator_code == "WHS4_544"))

  # Cases
  expect_true(any(map$key == "rubella_cases" & map$indicator_code == "WHS3_57"))
})
