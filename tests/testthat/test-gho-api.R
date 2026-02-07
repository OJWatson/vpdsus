test_that("gho_get works with httptest2 mock", {
  skip_if_not_installed("httptest2")

  httptest2::with_mock_api({
    res <- gho_get("Indicator", query = list(`$top` = 1), cache = FALSE)
    expect_s3_class(res, "tbl_df")
    expect_true(nrow(res) == 1)
    expect_true(all(c("IndicatorCode", "IndicatorName") %in% names(res)))
  })
})
