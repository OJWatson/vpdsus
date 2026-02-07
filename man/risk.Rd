\name{risk}
\title{Risk ranking and plotting}
\description{Rank locations by susceptibility and produce simple diagnostic and ranking plots.}

\alias{risk_rank}
\alias{plot_coverage_rank}
\alias{plot_susceptible_rank}
\alias{plot_panel_diagnostics}

\usage{
risk_rank(
  panel,
  suscept,
  window_years = 15,
  year_end = NULL,
  metric = c("susceptible_n", "susceptible_prop"),
  summarise_fun = c("mean", "sum", "max")
)

plot_coverage_rank(rank_tbl, top_n = 30)

plot_susceptible_rank(rank_tbl, top_n = 30)

plot_panel_diagnostics(panel)
}

\arguments{
\item{panel}{Panel tibble.}
\item{suscept}{Susceptibility estimates tibble, typically from \code{\link{estimate_susceptible_static}} or related functions.}
\item{window_years}{Window length (years) to summarise over.}
\item{year_end}{End year for the window (defaults to max year in data).}
\item{metric}{Which susceptibility metric to rank on.}
\item{summarise_fun}{How to summarise across the window.}
\item{rank_tbl}{A rank table returned by \code{\link{risk_rank}}.}
\item{top_n}{Number of top rows to show.}
}

\value{\code{risk_rank()} returns a tibble; plot functions return a ggplot object.}
