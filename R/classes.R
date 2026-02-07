#' A joined country-year panel for VPD susceptibility
#'
#' `vpd_panel` is a tibble with an additional class used throughout `{vpdsus}`.
#' It is typically created with [build_panel()] or [vpdsus_example_panel()].
#'
#' @details
#' Minimum expected columns:
#' - `iso3` (character)
#' - `year` (integer)
#' - `coverage` (numeric)
#' - `cases` (numeric)
#' - demography columns such as `pop_total`, `pop_0_4`, `pop_5_14`, `births`
#'
#' The object may carry join diagnostics in `attr(x, "diagnostics")`.
#'
#' @name vpd_panel
#' @aliases vpd_panel-class
NULL
