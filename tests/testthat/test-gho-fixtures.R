test_that("gho_build_url constructs expected OData URL", {
  q <- setNames(
    list("SpatialDim eq 'USA' and TimeDim eq 2020", 5),
    c("$filter", "$top")
  )
  url <- gho_build_url("WHS8_110", q)
  expect_match(url, "^https://ghoapi\\.azureedge\\.net/api/WHS8_110\\?")
  expect_match(url, "\\$filter=")
  expect_match(url, "\\$top=5")
  expect_match(url, "SpatialDim")
})

test_that("fixture parsing + standardisation works for coverage (MCV1)", {
  path <- system.file("extdata", "fixtures", "gho_WHS8_110_USA_2020.json", package = "vpdsus")
  txt <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  raw <- gho_parse_json(txt)
  std <- gho_standardise_coverage(raw)

  expect_true(is.data.frame(std))
  expect_true(all(c("iso3", "year", "coverage") %in% names(std)))
  expect_true(nrow(std) >= 1)
  expect_true(all(std$iso3 == "USA"))
  expect_true(all(std$year == 2020L))
  expect_true(all(std$coverage >= 0 & std$coverage <= 1))
})

test_that("fixture parsing + standardisation works for coverage (DTP3)", {
  path <- system.file("extdata", "fixtures", "gho_WHS4_100_USA_2020.json", package = "vpdsus")
  txt <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  raw <- gho_parse_json(txt)
  std <- gho_standardise_coverage(raw)

  expect_true(is.data.frame(std))
  expect_true(all(c("iso3", "year", "coverage") %in% names(std)))
  expect_true(nrow(std) >= 1)
  expect_true(all(std$iso3 == "USA"))
  expect_true(all(std$year == 2020L))
  expect_true(all(std$coverage >= 0 & std$coverage <= 1))
})

test_that("fixture parsing + standardisation works for coverage (Pol3)", {
  path <- system.file("extdata", "fixtures", "gho_WHS4_544_USA_2020.json", package = "vpdsus")
  txt <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  raw <- gho_parse_json(txt)
  std <- gho_standardise_coverage(raw)

  expect_true(is.data.frame(std))
  expect_true(all(c("iso3", "year", "coverage") %in% names(std)))
  expect_true(nrow(std) >= 1)
  expect_true(all(std$iso3 == "USA"))
  expect_true(all(std$year == 2020L))
  expect_true(all(std$coverage >= 0 & std$coverage <= 1))
})

test_that("fixture parsing + standardisation works for coverage (MCV2)", {
  path <- system.file("extdata", "fixtures", "gho_MCV2_USA_2020.json", package = "vpdsus")
  txt <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  raw <- gho_parse_json(txt)
  std <- gho_standardise_coverage(raw)

  expect_true(is.data.frame(std))
  expect_true(all(c("iso3", "year", "coverage") %in% names(std)))
  expect_true(nrow(std) >= 1)
  expect_true(all(std$iso3 == "USA"))
  expect_true(all(std$year == 2020L))
  expect_true(all(std$coverage >= 0 & std$coverage <= 1))
})

test_that("fixture parsing + standardisation works for cases", {
  path <- system.file("extdata", "fixtures", "gho_WHS3_62_USA_2020.json", package = "vpdsus")
  txt <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  raw <- gho_parse_json(txt)
  std <- gho_standardise_cases(raw)

  expect_true(is.data.frame(std))
  expect_true(all(c("iso3", "year", "cases") %in% names(std)))
  expect_true(nrow(std) >= 1)
  expect_true(all(std$iso3 == "USA"))
  expect_true(all(std$year == 2020L))
})

test_that("fixture parsing + standardisation works for cases (rubella)", {
  path <- system.file("extdata", "fixtures", "gho_WHS3_57_USA_2020.json", package = "vpdsus")
  txt <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  raw <- gho_parse_json(txt)
  std <- gho_standardise_cases(raw)

  expect_true(is.data.frame(std))
  expect_true(all(c("iso3", "year", "cases") %in% names(std)))
  expect_true(nrow(std) >= 1)
  expect_true(all(std$iso3 == "USA"))
  expect_true(all(std$year == 2020L))
})

test_that("gho_find_indicator returns empty tibble (not error) on no matches", {
  out <- gho_find_indicator("___definitely_not_a_real_indicator_keyword___", top_n = 5)
  expect_true(is.data.frame(out))
  expect_true(identical(names(out), c("indicator_code", "indicator_name")))
})
