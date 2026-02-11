test_that("gho_find_indicator(offline=TRUE) returns fixture results for measles", {
  out <- gho_find_indicator("measles", top_n = 10, offline = TRUE)
  expect_true(is.data.frame(out))
  expect_true(all(c("indicator_code", "indicator_name") %in% names(out)))
  expect_true(nrow(out) >= 1)
  expect_true(any(grepl("measles", tolower(out$indicator_name))))
})
