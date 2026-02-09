test_that("odin2_inputs_from_tibble aligns vectors to times", {
  df <- tibble::tibble(
    year = 2000:2003,
    births = c(1, 2, 3, 4),
    vaccinated = c(0, 1, 0, 1),
    cases = c(10, 0, 0, 5)
  )

  out <- odin2_inputs_from_tibble(df, times = c(2001, 2003))
  expect_named(out, c("births", "vaccinated", "cases"))
  expect_equal(out$births, c(2, 4))
  expect_equal(out$vaccinated, c(1, 1))
  expect_equal(out$cases, c(0, 5))
})

test_that("odin2_inputs_from_tibble supports iso3 filtering", {
  df <- tibble::tibble(
    iso3 = c("AAA", "AAA", "BBB", "BBB"),
    year = c(2000, 2001, 2000, 2001),
    births = c(1, 2, 10, 20),
    vaccinated = 0,
    cases = 0
  )

  out <- odin2_inputs_from_tibble(df, times = 2000:2001, iso3 = "BBB")
  expect_equal(out$births, c(10, 20))
})

test_that("odin2_inputs_from_tibble errors on missing years", {
  df <- tibble::tibble(year = 2000, births = 1, vaccinated = 0, cases = 0)
  expect_error(
    odin2_inputs_from_tibble(df, times = c(2000, 2001)),
    "does not cover"
  )
})
