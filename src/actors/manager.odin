package actors

/*
User capable of open/closing accounts and transfering funds between accounts.
*/
Manager :: struct {
    individual: ^Individual,
    username: string,
    password: string,
}

/*
# Overview
Create a new 'Manager' structure using the provided information.

# Parameters
## individual
The individual to whom the account belongs.

## username
The username for the account.

## password
The password for the account.

# Returns
## construct
The newly created 'Manager' structure.
*/
manager_constructor :: proc(individual: ^Individual, username: string, password: string) -> (construct: Manager) {
    return Manager{individual, username, password}
}