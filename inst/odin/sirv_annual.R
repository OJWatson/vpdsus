# Annual SIRV model with reporting
# Compartments: S, I, R, V
# Flows:
#  births -> S
#  vaccination S -> V
#  infection S -> I
#  recovery I -> R
#  mortality from all compartments

beta <- parameter(0.5)
gamma <- parameter(0.2)
mu <- parameter(0.01)
rho <- parameter(0.2)

births <- parameter(0)
vaccinated <- parameter(0)
n_pop <- parameter(1)

S0 <- parameter(0)
I0 <- parameter(0)
R0 <- parameter(0)
V0 <- parameter(0)

initial(S) <- S0
initial(I) <- I0
initial(R) <- R0
initial(V) <- V0
initial(reported_cases) <- 0
initial(susceptible_n) <- S0
initial(susceptible_prop) <- if (n_pop > 0) S0 / n_pop else 0

inf <- beta * S * I / n_pop
rec <- gamma * I
death_S <- mu * S
death_I <- mu * I
death_R <- mu * R
death_V <- mu * V

update(S) <- max(0, S + births - vaccinated - inf - death_S)
update(I) <- max(0, I + inf - rec - death_I)
update(R) <- max(0, R + rec - death_R)
update(V) <- max(0, V + vaccinated - death_V)
update(reported_cases) <- rho * inf
update(susceptible_n) <- S
update(susceptible_prop) <- if (n_pop > 0) S / n_pop else 0
