test_that("M3 golden: example static susceptibility + WHO-style ranking is stable", {
  panel <- vpdsus_example_panel()

  # Minimum deliverable: method A (static) susceptibility on shipped example data
  suscept <- estimate_susceptible_static(panel, coverage_col = "coverage", pop_col = "pop_0_4")
  expect_true(is.data.frame(suscept))
  expect_true(all(c("iso3", "year", "susceptible_n", "susceptible_prop") %in% names(suscept)))

  # WHO-style ranking output (risk categories + global rank)
  rank <- risk_rank(panel = panel, suscept = suscept)
  expect_true(is.data.frame(rank))
  expect_true(all(c("iso3", "susceptible_prop", "rank_global", "risk_category") %in% names(rank)))

  # Golden expectations for shipped example dataset
  expect_equal(rank$iso3, c("NGA", "PHL", "AFG"))
  expect_equal(rank$rank_global, c(1L, 2L, 3L))
  expect_equal(as.character(rank$risk_category), c("high", "medium", "high"))
  expect_equal(rank$susceptible_prop, c(0.43, 0.29, 0.33), tolerance = 1e-2)

  # First WHO-style output plot objects should build without error
  p_cov <- plot_coverage_rank(rank)
  p_sus <- plot_susceptible_rank(rank)
  expect_s3_class(p_cov, "ggplot")
  expect_s3_class(p_sus, "ggplot")
})
