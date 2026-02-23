# Minimal discrete-time model:
# S(t + 1) = S(t) + inc
inc <- parameter(1)
initial(S) <- 0
update(S) <- S + inc
