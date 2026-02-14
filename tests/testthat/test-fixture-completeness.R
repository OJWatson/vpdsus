test_that("all shipped GHO JSON fixtures have matching meta.json", {
  fixtures_dir <- system.file("extdata", "fixtures", package = "vpdsus")
  expect_true(nzchar(fixtures_dir))

  json_files <- list.files(fixtures_dir, pattern = "\\.json$", full.names = FALSE)
  json_files <- json_files[!grepl("\\.meta\\.json$", json_files)]

  expect_true(length(json_files) > 0)

  for (f in json_files) {
    meta <- sub("\\.json$", ".meta.json", f)
    expect_true(file.exists(file.path(fixtures_dir, meta)), info = paste("Missing meta for", f))
  }
})

test_that("fixtures cover all default indicator mappings (USA 2020)", {
  fixtures_dir <- system.file("extdata", "fixtures", package = "vpdsus")
  expect_true(nzchar(fixtures_dir))

  map <- vpd_indicators()
  codes <- unique(map$indicator_code)

  for (code in codes) {
    f <- sprintf("gho_%s_USA_2020.json", code)
    expect_true(file.exists(file.path(fixtures_dir, f)), info = paste("Missing fixture for", code))
    expect_true(file.exists(file.path(fixtures_dir, sub("\\.json$", ".meta.json", f))),
      info = paste("Missing meta fixture for", code)
    )
  }
})

test_that("fixtures cover offline gho_find_indicator keywords", {
  fixtures_dir <- system.file("extdata", "fixtures", package = "vpdsus")
  expect_true(nzchar(fixtures_dir))

  keywords <- c(
    "Measles",
    "DTP3",
    "Polio",
    "Rubella",
    "MCV1",
    "MCV2",
    "HEPB3",
    "HIB3",
    "PCV3",
    "pertussis"
  )

  for (k in keywords) {
    f <- sprintf("gho_Indicator_contains_%s_top10.json", k)
    expect_true(file.exists(file.path(fixtures_dir, f)), info = paste("Missing indicator search fixture for", k))
    expect_true(file.exists(file.path(fixtures_dir, sub("\\.json$", ".meta.json", f))),
      info = paste("Missing meta for indicator search fixture", k)
    )
  }
})
