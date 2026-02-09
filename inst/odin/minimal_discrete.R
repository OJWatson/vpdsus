# odin2 template: minimal discrete-time model (for tests/vignette)
#
# Simple difference equation:
#   S_{t+1} = S_t + inc
#
# This file is read by vpdsus::odin2_build_model(model = "minimal_discrete").

model <- odin2::odin({
  # Parameter (override at instantiation/simulation time)
  inc <- parameter(1)

  # NOTE: for discrete-time odin2 models, initial() cannot depend on parameters.
  # We set initial state via vpdsus::odin2_simulate(initial = ...).
  initial(S) <- 0

  update(S) <- S + inc
})
