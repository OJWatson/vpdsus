test_that("gho_cache_key is stable for identical endpoint/query", {
  q <- setNames(
    list("SpatialDim eq 'USA' and TimeDim eq 2020", 5),
    c("$filter", "$top")
  )

  k1 <- gho_cache_key("WHS8_110", q)
  k2 <- gho_cache_key("WHS8_110", q)

  expect_type(k1, "character")
  expect_equal(k1, k2)
  expect_match(k1, "^WHS8_110_")
})
