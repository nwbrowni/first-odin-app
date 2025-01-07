package main

import "core:fmt"
import "src/accounts"
import "src/actors"

main :: proc() {
    test_account()
}

test_account :: proc() {
    ind := actors.individual_constructor("Nate", "Brown", "0")
    holder := actors.holder_constructor(&ind, "user", "pass")
    acc := accounts.account_constructor("0", "0", 100, &holder)
    fmt.println("account balance:", acc.balance)
    fmt.println("account has no flags:", len(&acc.flags),"(flag array length)")
    fmt.println("withdraw $1,000:", accounts.withdraw(&acc, 1000),"(withdraw operation success indicator)")
    fmt.println("account now flagged as overdrawn:", acc.flags[0],"(first flag in flag array)")
    accounts.clear_flags(&acc)
    fmt.println("account now has no flags:", len(&acc.flags),"(flag array length)")
    accounts.deposit(&acc, accounts.calculate_interest(&acc, 0.05))
    fmt.println("account balance:", acc.balance)
}