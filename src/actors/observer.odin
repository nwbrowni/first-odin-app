package actors

/*
User capable of viewing the funds in accounts.
*/
Observer :: struct {
    individual: ^Individual,
    username: string,
    password: string,
}

/*
# Overview
Create a new 'Observer' structure using the provided information.

# Parameters
## individual
The individual to whom the account belongs.

## username
The username for the account.

## password
The password for the account.

# Returns
## construct
The newly created 'Observer' structure.
*/
observer_constructor :: proc(individual: ^Individual, username: string, password: string) -> (construct: Observer) {
    return Observer{individual, username, password}
}