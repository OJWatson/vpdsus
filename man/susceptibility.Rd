\name{susceptibility}
\title{Susceptibility estimation methods}
\description{Estimate susceptible counts or proportions from vaccination, births, and case series.}

\alias{estimate_susceptible_static}
\alias{estimate_susceptible_cohort}
\alias{estimate_susceptible_cohort_ve}
\alias{estimate_susceptible_case_balance}

\usage{
estimate_susceptible_static(
  panel,
  coverage_col = "coverage",
  pop_col = "pop_0_4",
  age_group = "0-4",
  ve = 1
)

estimate_susceptible_cohort(
  panel,
  years_back = 4,
  coverage_col = "coverage",
  births_col = "births",
  pop_col = "pop_0_4",
  age_group = "0-4"
)

estimate_susceptible_cohort_ve(
  panel,
  years_back = 4,
  c1_col = "mcv1",
  c2_col = "mcv2",
  births_col = "births",
  pop_col = "pop_0_4",
  age_group = "0-4",
  ve1 = 0.93,
  ve2 = 0.97
)

estimate_susceptible_case_balance(
  panel,
  rho = c(0.05, 0.1, 0.2, 0.5, 1),
  coverage_col = "coverage",
  births_col = "births",
  cases_col = "cases",
  pop_col = "pop_total",
  age_group = "total",
  s0 = NULL
)
}

\arguments{
\item{panel}{A panel tibble, typically from \code{\link{build_panel}}.}
\item{coverage_col}{Name of the coverage column (proportion in [0,1]).}
\item{pop_col}{Population denominator column.}
\item{age_group}{Label to place in the returned \code{age_group} column.}
\item{ve}{Vaccine efficacy multiplier (default 1).}
\item{years_back}{Number of years to include in the age group window (e.g. 4 for ages 0--4).}
\item{births_col}{Name of births column.}
\item{c1_col}{Coverage column for dose 1.}
\item{c2_col}{Coverage column for dose 2.}
\item{ve1}{Vaccine efficacy for dose 1.}
\item{ve2}{Vaccine efficacy for dose 2.}
\item{rho}{Reporting fraction(s).}
\item{cases_col}{Name of case-count column.}
\item{s0}{Optional initial susceptible count.}
}

\value{A tibble with susceptible counts and proportions.}
