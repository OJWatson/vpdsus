test_that("gho_find_indicator(offline=TRUE) returns fixture results for measles", {
  out <- gho_find_indicator("measles", top_n = 10, offline = TRUE)
  expect_true(is.data.frame(out))
  expect_true(all(c("indicator_code", "indicator_name") %in% names(out)))
  expect_true(nrow(out) >= 1)
  expect_true(any(grepl("measles", tolower(out$indicator_name))))
  expect_true(any(out$indicator_code %in% c("WHS3_62", "WHS8_110", "MCV2")))
})

test_that("gho_find_indicator(offline=TRUE) returns pinned fixtures for additional indicators", {
  dtp3 <- gho_find_indicator("DTP3", top_n = 10, offline = TRUE)
  expect_true(nrow(dtp3) >= 1)
  expect_true(any(dtp3$indicator_code == "WHS4_100"))

  polio <- gho_find_indicator("polio", top_n = 10, offline = TRUE)
  expect_true(nrow(polio) >= 1)
  expect_true(any(polio$indicator_code == "WHS4_544"))

  rubella <- gho_find_indicator("Rubella", top_n = 10, offline = TRUE)
  expect_true(nrow(rubella) >= 1)
  expect_true(any(rubella$indicator_code == "WHS3_57"))

  mcv1 <- gho_find_indicator("MCV1", top_n = 10, offline = TRUE)
  expect_true(nrow(mcv1) >= 1)
  expect_true(any(mcv1$indicator_code == "WHS8_110"))

  mcv2 <- gho_find_indicator("MCV2", top_n = 10, offline = TRUE)
  expect_true(nrow(mcv2) >= 1)
  expect_true(any(mcv2$indicator_code == "MCV2"))
})
