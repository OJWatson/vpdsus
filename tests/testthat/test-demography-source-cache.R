test_that("get_demography() respects vpdsus.demography_source option", {
  withr::local_options(list(vpdsus.demography_source = "fixture_wpp"))

  d <- get_demography(years = 2020, countries = "USA")

  expect_true(is.data.frame(d))
  expect_equal(unique(d$iso3), "USA")
  expect_equal(unique(d$year), 2020L)
})

test_that("demography cache key is stable and order-insensitive", {
  withr::local_envvar(list(XDG_CACHE_HOME = tempfile("vpdsus-cache-")))

  k1 <- demography_cache_key(source = "fixture_wpp", years = c(2021, 2020), countries = c("FRA", "usa"))
  k2 <- demography_cache_key(source = "fixture_wpp", years = c(2020, 2021), countries = c("USA", "FRA"))

  expect_equal(k1, k2)

  d1 <- get_demography(source = "fixture_wpp", years = c(2021, 2020), countries = c("FRA", "usa"), cache = TRUE)
  d2 <- get_demography(source = "fixture_wpp", years = c(2020, 2021), countries = c("USA", "FRA"), cache = TRUE)

  expect_equal(d1, d2)

  path <- cache_paths_demography(k1, ext = "rds")
  expect_true(file.exists(path))
})
