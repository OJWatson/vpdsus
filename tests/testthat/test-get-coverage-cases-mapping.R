test_that("get_coverage uses default vpd_indicators mappings for additional antigens", {
  read_fixture <- function(name) {
    path <- system.file("extdata", "fixtures", name, package = "vpdsus")
    txt <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
    gho_parse_json(txt)
  }

  # DTP3
  called <- NULL
  mock_get_indicator <- function(indicator_code) {
    called <<- indicator_code
    read_fixture("gho_WHS4_100_USA_2020.json")
  }
  testthat::local_mocked_bindings(gho_get_indicator = mock_get_indicator, .package = "vpdsus")

  out <- get_coverage("DTP3", years = 2020L, countries = "USA")
  expect_identical(called, "WHS4_100")
  expect_true(is.data.frame(out))
  expect_true(all(c("iso3", "year", "coverage") %in% names(out)))
  expect_true(all(out$iso3 == "USA"))
  expect_true(all(out$year == 2020L))
  expect_true(all(out$coverage >= 0 & out$coverage <= 1))
})

test_that("get_coverage uses default vpd_indicators mappings for Pol3", {
  read_fixture <- function(name) {
    path <- system.file("extdata", "fixtures", name, package = "vpdsus")
    txt <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
    gho_parse_json(txt)
  }

  called <- NULL
  mock_get_indicator <- function(indicator_code) {
    called <<- indicator_code
    read_fixture("gho_WHS4_544_USA_2020.json")
  }
  testthat::local_mocked_bindings(gho_get_indicator = mock_get_indicator, .package = "vpdsus")

  out <- get_coverage("POL3", years = 2020L, countries = "USA")
  expect_identical(called, "WHS4_544")
  expect_true(is.data.frame(out))
  expect_true(all(c("iso3", "year", "coverage") %in% names(out)))
  expect_true(all(out$iso3 == "USA"))
  expect_true(all(out$year == 2020L))
})

test_that("get_cases uses default vpd_indicators mappings for rubella", {
  read_fixture <- function(name) {
    path <- system.file("extdata", "fixtures", name, package = "vpdsus")
    txt <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
    gho_parse_json(txt)
  }

  called <- NULL
  mock_get_indicator <- function(indicator_code) {
    called <<- indicator_code
    read_fixture("gho_WHS3_57_USA_2020.json")
  }
  testthat::local_mocked_bindings(gho_get_indicator = mock_get_indicator, .package = "vpdsus")

  out <- get_cases("rubella", years = 2020L, countries = "USA")
  expect_identical(called, "WHS3_57")
  expect_true(is.data.frame(out))
  expect_true(all(c("iso3", "year", "cases") %in% names(out)))
  expect_true(all(out$iso3 == "USA"))
  expect_true(all(out$year == 2020L))
})
