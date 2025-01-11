package accounts

import "core:fmt"
import "core:thread"
import "../utilities"
import "../actors"

/*
Flags that can be applied to an account.
*/
AccountFlag :: enum {
    Overdrawn,
    Freeze,
}

/*
A structure representing an account.
*/
Account :: struct {
    routing_number: string,
    account_number: string,
    owners: [dynamic]^actors.Holder,
    balance: f64,
    flags: [dynamic]AccountFlag,
    lock: b64,
}

/*
# Overview
Create a new Account structure using the provided information.

# Parameters
## routing
The account routing number.

## account
The account number.

## balance
The current balance on the account.

## owners
The owner(s) to be placed on the account. This is parameterized and can have multiple owners.

# Returns
## construct
The newly generated account.
*/
account_constructor :: proc(routing: string, account: string, balance: f64, owners: ..^actors.Holder) -> (construct: Account) {
    temp_owners: [dynamic]^actors.Holder
    for element in owners {
        append(&temp_owners, element)
    }
    return Account{routing, account, temp_owners, balance, [dynamic]AccountFlag{}, b64(false)}
}

/*
# Overview
Atomically lock the 64-bit "lock", which is being used as a mutex for the structure. NOTICE: This is only intended for
internal library use.

# Parameters
## account
The target account.

# Returns
## sucess
Boolean indicating whether or not the boolean was successfully locked.
*/
lock_account :: proc(account: ^Account) -> (success: bool) {
    // This uses OS level operations at an atomic level (hopefully)
    // this means that the value is compared to the promised, then updated to new (atomic)
    // the function then returns the new value and a boolean telling you if promised matched
    // this is effectively (I think) calling assembly compare and then exchange as a critical code section
    // pulled from https://github.com/odin-lang/Odin/blob/master/examples/demo/demo.odin
    // res, ok := intrinsics.atomic_compare_exchange_strong(&account.lock, false, true)
    // return ok && res == false
    return utilities.lock_cheap_mutex(&account.lock)
}

/*
# Overview
Release the locked 64-bit "lock" being used as the accounts mutex. NOTICE: This is only intended for internal library
use.

# Parameters
## account
The target account.
*/
unlock_account :: proc(account: ^Account) {
    // account.lock = false;
    utilities.unlock_cheap_mutex(&account.lock)
}

/*
# Overview
Calculate the interest owed an account based on the provided rate.

# Parameters
## account
The target account.

## rate
The interest to be used for interest calculations.

# Returns
## amount
The interest owned the specified account calculated using the provided rate.
*/
calculate_interest :: proc(account: ^Account, rate: f64) -> (amount: f64) {
    return account.balance * rate
}

/*
# Overview
Add the provided flag to the specified account (if it has not been already). This is thread safe (I hope).

# Parameters
## account
The target account.

## flag
The new flag.
*/
exclusive_add_flag :: proc(account: ^Account, flag: AccountFlag) {
    for !lock_account(account) { thread.yield() }
    defer unlock_account(account)
    found := false
    for existing in account.flags {
        if existing == flag { found |= true }
    }
    if !found { append(&account.flags, flag)}
}

/*
# Overview
Remove all flags from the account. This is thread safe (I hope).

# Parameters
## account
The target account.
*/
clear_flags :: proc(account: ^Account) {
    for !lock_account(account) { thread.yield() }
    defer unlock_account(account)
    account.flags = [dynamic]AccountFlag{}
}

BalanceOperation :: enum {
    Increase,
    Decrease,
}

UpdateBalanceOutcome :: enum {
    Success,
    InsufficientFunds,
}

/*
# Overview
Update the balance of an account. This is thread safe (I hope).

# Parameters
## account
The target account.

## operation
The intended operation. 'Increase' will result in the amount being added to the balance, while 'Decrease' will result
in the amount being removed from the balance. 'Increase' is intended for use with deposits. 'Decrease' is intended for
use with withdrawals.

## amount
The amount to be used in the requested operation.

# Returns
## outcome
The point at which the operation stopped. If the entire operation was completed 'Success' will be returned. If the
operation was 'Decrease' and the amount was greater than the balance, 'InsufficientFunds' will be returned.
*/
update_balance :: proc(account: ^Account, operation: BalanceOperation, amount: f64) -> (outcome: UpdateBalanceOutcome) {
    for !lock_account(account) { thread.yield() }
    defer unlock_account(account)
    if account.balance < amount { return UpdateBalanceOutcome.InsufficientFunds }
    switch operation {
        case BalanceOperation.Decrease:
            if account.balance < amount { return UpdateBalanceOutcome.InsufficientFunds }
            account.balance -= amount
        case BalanceOperation.Increase:
            account.balance += amount
    }
    return UpdateBalanceOutcome.Success
}

/*
# Overview
Deposit a certain amount of money into an account. As a result, the account's balance will be increased to reflect the
newly depositied amount.

# Parameters
## account
The target account.

## amount
The amount to be added to the account's balance.

# Returns
## success
A boolean indicator of operation success or failure.
*/
deposit :: proc(account: ^Account, amount: f64) -> (success: bool) {
    if account_is_frozen(account) { return false }
    if update_balance(account, BalanceOperation.Increase, amount) != UpdateBalanceOutcome.Success { return false }
    return true
}

/*
# Overview
Withdraw a certain amount from an account. As a result, the account's balance will be decreased to reflec the amount
withdrawn. If there is an insufficient balance in the account, the withdraw will fail and an Overdrawn flag will be
added to the account.

# Parameters
## account
The target account.

## amount
The amount to be withdrawn from the account

# Returns
## success
A boolean indicator of operation success or failure.
*/
withdraw :: proc(account: ^Account, amount: f64) -> (success: bool) {
    if account_is_frozen(account) { return false }
    result := update_balance(account, BalanceOperation.Decrease, amount)
    if result == UpdateBalanceOutcome.InsufficientFunds {
        exclusive_add_flag(account, AccountFlag.Overdrawn)
        return false
    }
    else if result != UpdateBalanceOutcome.Success { return false }
    return true
}

/*
# Overview
See if the specified account has the locked flag applied.

# Parameters
## account
The target account.

# Returns
## locked
A boolean indicating if a locked flag was found for the specified account.
*/
account_is_frozen :: proc(account: ^Account) -> (locked: bool) {
    for flag in account.flags {
        if flag == AccountFlag.Freeze { return true }
    }
    return false
}

/*
# Overview
Transfer an amount from a source account to a destination account. If at any point the transfer operation fails, funds
will be returned to the source account.

# Parameters
## source
The account from which the funds will originate.

## destination
The account to which the funds are being transfered.

## amount
The amount being transfered from the source account to the destination account.

# Returns
## success
Boolean indicating operation success/failure.
*/
transaction :: proc(source: ^Account, destination: ^Account, amount: f64) -> (success: bool) {
    if !withdraw(source, amount) { return false }
    if !deposit(destination, amount) {
        deposit(source, amount)  // return withdrawn money to source account
        return false
    }
    return true
}