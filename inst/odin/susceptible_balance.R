# Susceptible balance (discrete-time, with explicit S0 parameter)
rho <- parameter(1)
births <- parameter(0)
vaccinated <- parameter(0)
cases <- parameter(0)
S0 <- parameter(0)
initial(S) <- S0
update(S) <- max(0, S + births - vaccinated - cases / rho)
