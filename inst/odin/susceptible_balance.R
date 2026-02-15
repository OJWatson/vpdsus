# odin2 template: susceptible balance (case-driven)
# This file is read by vpdsus::odin2_build_model().
#
# Note: exact odin2 syntax may evolve; this is a scaffold.

model <- odin2::odin({
  # Parameters
  rho <- parameter(1)
  births <- parameter(0)
  vaccinated <- parameter(0)
  cases <- parameter(0)
  S0 <- parameter(0)

  initial(S) <- S0

  update(S) <- max(0, S + births - vaccinated - cases / rho)

  output(S) <- S
})
