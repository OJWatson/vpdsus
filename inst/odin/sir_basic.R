# Simple SIR with vaccination (continuous-time)
beta <- parameter(0.5)
gamma <- parameter(0.2)
v <- parameter(0)
births <- parameter(0)
n_pop <- parameter(1)
S0 <- parameter(0)
I0 <- parameter(0)
R0 <- parameter(0)
initial(S) <- S0
initial(I) <- I0
initial(R) <- R0
deriv(S) <- births - beta * S * I / n_pop - v * S
deriv(I) <- beta * S * I / n_pop - gamma * I
deriv(R) <- gamma * I + v * S
