\name{demography}
\title{Demography helpers}
\description{Retrieve or provide demographic series used in susceptibility and modelling workflows.}

\alias{get_demography}
\alias{vpdsus_example_panel}

\usage{
get_demography(years = NULL, countries = NULL, source = c("example", "wpp"))

vpdsus_example_panel()
}

\arguments{
\item{years}{Optional integer vector of years to filter to.}
\item{countries}{Optional character vector of ISO3 codes to filter to.}
\item{source}{Data source. \code{"example"} uses a small built-in dataset shipped with the package; \code{"wpp"} uses the \pkg{wpp2024} package if installed.}
}

\value{A tibble.}

\details{\code{vpdsus_example_panel()} returns a small example panel useful for running the package examples and vignettes without live downloads.}
