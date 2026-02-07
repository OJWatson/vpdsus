\name{odin2_helpers}
\title{Mechanistic modelling with odin2}
\description{Helpers to build and simulate simple odin2 mechanistic models and compare them to panel-derived estimates.}

\alias{odin2_build_model}
\alias{odin2_simulate}
\alias{compare_methods}

\usage{
odin2_build_model(model = c("balance", "sir"), file = NULL)

odin2_simulate(model, times, pars = list(), initial = list(), inputs = NULL)

compare_methods(panel, estimates, iso3)
}

\arguments{
\item{model}{For \code{odin2_build_model()}, a model name; for \code{odin2_simulate()}, an odin2 model object.}
\item{file}{Optional path to an odin2 model file.}
\item{times}{Numeric vector of times to simulate.}
\item{pars}{Named list of parameter values.}
\item{initial}{Named list of initial conditions.}
\item{inputs}{Optional inputs passed to odin2.}
\item{panel}{Panel tibble.}
\item{estimates}{A list or tibble of estimates to compare.}
\item{iso3}{ISO3 code to filter to.}
}

\value{Model objects, simulations, and comparison tibbles/plots depending on function.}

\details{These functions require the \pkg{odin2} package (Suggested).}
