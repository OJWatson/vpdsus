# odin2 template: susceptible balance (case-driven)
# This file is read by vpdsus::odin2_build_model().
#
# Note: exact odin2 syntax may evolve; this is a scaffold.

odin2::odin({
  initial(S) <- S0

  update(S) <- max(0, S + births - vaccinated - cases / rho)

  output(S) <- S
})
