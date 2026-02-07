# Declare commonly-used NSE variables to appease R CMD check notes
utils::globalVariables(c(
  ".data",
  "Estimate",
  "Std. Error",
  "z value",
  "Pr(>|z|)",
  "iso3",
  "year",
  "year_next",
  "cases_next",
  "susceptible_prop"
))
