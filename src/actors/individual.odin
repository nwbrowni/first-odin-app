package actors

Individual :: struct {
    first: string,
    last: string,
    social_security_number: string,
}

/*
# Overview
Create a new 'Individual' structure using the provided information.

# Parameters
## first
The first name to be used.

## last
The last name to be used.

## ssn
The social security number to be associated with the account.

# Returns
## construct
The newly created 'Individual' structure.
*/
individual_constructor :: proc(first: string, last: string, ssn: string) -> (construct: Individual) {
    return Individual{first, last, ssn}
}