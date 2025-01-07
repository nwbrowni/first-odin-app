package actors

/*
User in control of other user accounts.
*/
Administrator :: struct {
    individual: ^Individual,
    username: string,
    password: string,
}

/*
# Overview
Create a new 'Administrator' structure using the provided information.

# Parameters
## individual
The individual to whom the account belongs.

## username
The username for the account.

## password
The password for the account.

# Returns
## construct
The newly created 'Administrator' structure.
*/
administrator_constructor :: proc(individual: ^Individual, username: string, password: string) -> (construct: Administrator) {
    return Administrator{individual, username, password}
}