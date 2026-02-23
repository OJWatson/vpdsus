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

  # Global shipped panel should produce a non-trivial ranking table.
  expect_true(nrow(rank) > 100)
  rank_non_na <- rank[!is.na(rank$rank_global), , drop = FALSE]
  expect_equal(rank_non_na$rank_global, seq_len(nrow(rank_non_na)))
  expect_true(all(rank$susceptible_prop >= 0 & rank$susceptible_prop <= 1, na.rm = TRUE))
  expect_true(any(rank$iso3 == "NGA"))

  # First WHO-style output plot objects should build without error
  p_cov <- plot_coverage_rank(rank)
  p_sus <- plot_susceptible_rank(rank)
  expect_s3_class(p_cov, "ggplot")
  expect_s3_class(p_sus, "ggplot")
})
