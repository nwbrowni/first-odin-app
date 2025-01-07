package utilities

import "base:intrinsics"

/*
# Overview
Atomically lock the boolean "lock", which is being used as a mutex for the structure. NOTICE: This is only intended for
internal library use.

# Parameters
## cheap_mutex
Target 64-bit type being used as a mutex.

# Returns
## sucess
Boolean indicating whether or not the boolean was successfully locked.
*/
lock_cheap_mutex :: proc(cheap_mutex: ^b64) -> (success: bool) {
    // This uses OS level operations at an atomic level (hopefully)
    // this means that the value is compared to the promised, then updated to new (atomic)
    // the function then returns the new value and a boolean telling you if promised matched
    // this is effectively (I think) calling assembly compare and then exchange as a critical code section
    // pulled from https://github.com/odin-lang/Odin/blob/master/examples/demo/demo.odin
    res, ok := intrinsics.atomic_compare_exchange_strong(cheap_mutex, false, true)
    return ok && res == false
}

/*
# Overview
Release the lock boolean being used as the accounts mutex. NOTICE: This is only intended for internal library use.

# Parameters
## cheap_mutex
Target 64-bit type being used as a mutex.
*/
unlock_cheap_mutex :: proc(cheap_mutex: ^b64) {
    cheap_mutex^ = false;
}