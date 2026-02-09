# odin2 template: susceptible balance (discrete-time)
#
# Difference equation form suitable for yearly time steps:
#   S_{t+1} = max(0, S_t + births - vaccinated - cases / rho)
#
# Parameters are declared with parameter() so they can be overridden at
# instantiation/simulation time.

model <- odin2::odin({
  # Parameters
  rho <- parameter(1)

  # Inputs (use scalars for now; can be extended to time-varying later)
  births <- parameter(0)
  vaccinated <- parameter(0)
  cases <- parameter(0)

  # NOTE: for discrete-time odin2 models, initial() cannot depend on parameters.
  # We set initial state via vpdsus::odin2_simulate(initial = ...).
  initial(S) <- 0

  update(S) <- max(0, S + births - vaccinated - cases / rho)
})
