\name{panel}
\title{Build and inspect VPD panels}
\description{Helpers to join coverage, case, and demographic series into a single analysis panel.}

\alias{build_panel}
\alias{panel_diagnostics}

\usage{
build_panel(coverage, cases, demography)

panel_diagnostics(panel)
}

\arguments{
\item{coverage}{Coverage tibble, typically from \code{\link{get_coverage}}.}
\item{cases}{Cases tibble, typically from \code{\link{get_cases}}.}
\item{demography}{Demography tibble, typically from \code{\link{get_demography}}.}
\item{panel}{A panel tibble, typically from \code{\link{build_panel}}.}
}

\value{A tibble.}
