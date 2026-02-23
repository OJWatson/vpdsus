# Susceptible balance (discrete-time):
# S(t + 1) = max(0, S(t) + births - vaccinated - cases / rho)
rho <- parameter(1)
births <- parameter(0)
vaccinated <- parameter(0)
cases <- parameter(0)
initial(S) <- 0
update(S) <- max(0, S + births - vaccinated - cases / rho)
