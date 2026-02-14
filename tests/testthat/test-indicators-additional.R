test_that("vpd_indicators includes verified indicator mappings (coverage + cases)", {
  map <- vpd_indicators()

  expect_true(is.data.frame(map))
  expect_true(all(c("key", "type", "antigen_or_disease", "indicator_code") %in% names(map)))

  # Coverage
  expect_true(any(map$key == "mcv1_coverage" & map$indicator_code == "WHS8_110"))
  expect_true(any(map$key == "mcv2_coverage" & map$indicator_code == "MCV2"))
  expect_true(any(map$key == "dtp3_coverage" & map$indicator_code == "WHS4_100"))
  expect_true(any(map$key == "pol3_coverage" & map$indicator_code == "WHS4_544"))
  expect_true(any(map$key == "hepb3_coverage" & map$indicator_code == "WHS4_117"))
  expect_true(any(map$key == "hib3_coverage" & map$indicator_code == "WHS4_129"))
  expect_true(any(map$key == "pcv3_coverage" & map$indicator_code == "PCV3"))

  # Cases
  expect_true(any(map$key == "measles_cases" & map$indicator_code == "WHS3_62"))
  expect_true(any(map$key == "rubella_cases" & map$indicator_code == "WHS3_57"))
  expect_true(any(map$key == "pertussis_cases" & map$indicator_code == "WHS3_43"))

  # Defensive: keys should be unique
  expect_true(!anyDuplicated(map$key))
})
