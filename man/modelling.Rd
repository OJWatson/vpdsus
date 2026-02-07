\name{modelling}
\title{Outbreak modelling helpers}
\description{Create outbreak outcomes, assemble modelling datasets, fit simple models, and evaluate them.}

\alias{make_outcome_outbreak}
\alias{make_modelling_panel}
\alias{fit_outbreak_models}
\alias{evaluate_models}

\usage{
make_outcome_outbreak(cases, pop, abs_threshold = 1000, pc_threshold = 10)

make_modelling_panel(
  panel,
  suscept,
  outcome = c("outbreak_pc", "outbreak_abs"),
  lag_years = 1
)

fit_outbreak_models(data)

evaluate_models(data, train_end = NULL)
}

\arguments{
\item{cases}{Numeric vector of cases.}
\item{pop}{Numeric vector of population.}
\item{abs_threshold}{Absolute case-count threshold used to label an outbreak.}
\item{pc_threshold}{Per-100k threshold used to label an outbreak.}
\item{panel}{Panel tibble.}
\item{suscept}{Susceptibility estimates tibble.}
\item{outcome}{Outcome type to create.}
\item{lag_years}{Lag between predictors and outcome.}
\item{data}{A modelling dataset, typically from \code{\link{make_modelling_panel}}.}
\item{train_end}{Optional end year for training subset.}
}

\value{Tibbles and/or model objects depending on function.}
