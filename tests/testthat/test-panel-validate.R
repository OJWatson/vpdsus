test_that("panel_validate passes a well-formed example panel", {
  panel <- vpdsus_example_panel()
  v <- panel_validate(panel, quiet = TRUE)

  expect_true(v$ok)
  expect_s3_class(v$issues, "tbl_df")
  expect_equal(nrow(v$issues), 0)
  expect_s3_class(v$diagnostics, "tbl_df")
  expect_equal(v$diagnostics$n_rows, nrow(panel))
})

test_that("panel_validate catches schema/value/key issues", {
  panel <- tibble::tibble(
    iso3 = c("AAA", "AAA", ""),
    year = c(2000L, 2000L, NA_integer_),
    coverage = c(0.9, 1.2, 0.5),
    cases = c(1, -2, 3),
    pop_total = c(1000, -5, 1200),
    births = c(20, 30, -1)
  )

  v <- panel_validate(panel, quiet = TRUE)

  expect_false(v$ok)
  msgs <- v$issues$issue
  expect_true(any(grepl("duplicated rows", msgs)))
  expect_true(any(grepl("outside \\[0, 1\\]", msgs)))
  expect_true(any(grepl("negative value", msgs)))
  expect_true(any(grepl("missing/non-finite", msgs)))
  expect_true(any(grepl("missing/blank", msgs)))
})

test_that("panel_validate reports missing required columns", {
  panel <- tibble::tibble(iso3 = "AAA", year = 2000L)
  v <- panel_validate(panel, quiet = TRUE)

  expect_false(v$ok)
  expect_true(any(grepl("missing required columns", v$issues$issue)))
})
