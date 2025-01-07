package actors

/*
User that controls the funds of an account.
*/
Holder :: struct {
    individual: ^Individual,
    username: string,
    password: string,
}

/*
# Overview
Create a new 'Holder' structure using the provided information.

# Parameters
## individual
The individual to whom the account belongs.

## username
The username for the account.

## password
The password for the account.

# Returns
## construct
The newly created 'Holder' structure.
*/
holder_constructor :: proc(individual: ^Individual, username: string, password: string) -> (construct: Holder) {
    return Holder{individual, username, password}
}