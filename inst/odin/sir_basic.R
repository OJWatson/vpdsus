# odin2 template: simple SIR with vaccination (scaffold)
#
# This template is intended as a starting point for mechanistic modelling.
# Parameters are declared explicitly so they can be overridden at
# instantiation/simulation time.

model <- odin2::odin({
  # Parameters
  beta <- parameter(0.5)
  gamma <- parameter(0.2)
  v <- parameter(0)
  births <- parameter(0)
  N <- parameter(1)

  # Initial conditions
  S0 <- parameter(0)
  I0 <- parameter(0)
  R0 <- parameter(0)

  initial(S) <- S0
  initial(I) <- I0
  initial(R) <- R0

  deriv(S) <- births - beta * S * I / N - v * S
  deriv(I) <- beta * S * I / N - gamma * I
  deriv(R) <- gamma * I + v * S

  output(S) <- S
  output(I) <- I
  output(R) <- R
})
