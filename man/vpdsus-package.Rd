\docType{package}
\name{vpdsus-package}
\alias{vpdsus}
\alias{vpdsus-package}
\title{vpdsus: Vaccine Preventable Disease Susceptibility Estimation and Risk Scanning}
\description{
Tools to retrieve WHO GHO immunisation coverage and reported cases, join with
basic demography, estimate susceptibility via progressive methods, produce
WHO-style risk ranking plots, and link susceptibility to outbreak risk.
}
\details{
Most users should start with:
\itemize{
\item \code{\link{get_coverage}}, \code{\link{get_cases}}, \code{\link{get_demography}}
\item \code{\link{build_panel}}
\item \code{\link{estimate_susceptible_static}}, \code{\link{estimate_susceptible_cohort}}
\item \code{\link{risk_rank}}, \code{\link{plot_coverage_rank}}, \code{\link{plot_susceptible_rank}}
}
}
\author{Oliver Watson}
