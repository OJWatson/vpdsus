test_that("odin2_balance_inputs_from_panel aligns and computes vaccinated", {
  panel <- tibble::tibble(
    iso3 = c("AAA", "AAA", "AAA"),
    year = 2000:2002,
    births = c(10, 20, 30),
    coverage = c(0.5, 1.2, -0.1),
    cases = c(1, 2, 3)
  )

  out <- odin2_balance_inputs_from_panel(panel, times = 2000:2002, iso3 = "AAA")
  expect_named(out, c("births", "vaccinated", "cases"))
  expect_equal(out$births, c(10, 20, 30))
  # coverage clamped to [0,1]
  expect_equal(out$vaccinated, c(10 * 0.5, 20 * 1, 30 * 0))
  expect_equal(out$cases, c(1, 2, 3))
})

test_that("odin2_balance_inputs_from_panel supports ve", {
  panel <- tibble::tibble(
    iso3 = "AAA",
    year = 2000,
    births = 10,
    coverage = 0.5,
    cases = 0
  )

  out <- odin2_balance_inputs_from_panel(panel, times = 2000, iso3 = "AAA", ve = 0.8)
  expect_equal(out$vaccinated, 10 * 0.5 * 0.8)
})
