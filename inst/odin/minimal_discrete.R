# odin2 template: minimal discrete-time model (for tests/vignette)
#
# Simple difference equation:
#   S_{t+1} = S_t + inc
#
# This file is read by vpdsus::odin2_build_model(model = "minimal_discrete").

model <- odin2::odin({
  # Parameters (override at instantiation/simulation time)
  S0 <- parameter(0)
  inc <- parameter(1)

  initial(S) <- S0

  update(S) <- S + inc
})
