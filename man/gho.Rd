\name{gho}
\title{WHO GHO data access helpers}
\description{Low-level accessors and convenience wrappers for the WHO Global Health Observatory (GHO) OData API.}
\details{These functions provide cached downloads and lightweight indicator mapping for coverage and cases series.}

\alias{gho_base_url}
\alias{gho_get}
\alias{gho_find_indicator}
\alias{gho_get_indicator}
\alias{vpd_indicators}
\alias{get_coverage}
\alias{get_cases}

\usage{
gho_base_url()

gho_get(endpoint, query = list(), cache = TRUE, quiet = TRUE)

gho_find_indicator(keyword, top_n = 50)

gho_get_indicator(indicator_code)

vpd_indicators()

get_coverage(antigen, indicator_code = NULL, years = NULL, countries = NULL)

get_cases(disease, indicator_code = NULL, years = NULL, countries = NULL)
}

\arguments{
\item{endpoint}{Character scalar, e.g. \code{"Indicator"} or an indicator code.}
\item{query}{Named list of OData query parameters.}
\item{cache}{Logical; whether to cache raw JSON responses.}
\item{quiet}{Logical; suppress progress messages.}
\item{keyword}{Keyword to search within indicator metadata.}
\item{top_n}{Maximum number of results to return.}
\item{indicator_code}{Indicator code (e.g., \code{"MCV1"}).}
\item{antigen}{Antigen string (e.g., \code{"MCV1"}, \code{"DTP3"}).}
\item{disease}{Disease string (e.g., \code{"measles"}).}
\item{years}{Optional integer vector of years to filter to.}
\item{countries}{Optional character vector of ISO3 codes to filter to.}
}

\value{A tibble.}

\seealso{\code{\link{build_panel}}}
