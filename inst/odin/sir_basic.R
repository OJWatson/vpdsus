# odin2 template: simple SIR with vaccination (scaffold)

model <- odin2::odin({
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
