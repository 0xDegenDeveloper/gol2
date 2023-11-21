fn raise_to_power(base: u128, exponent: u128) -> u256 {
    let mut result: u256 = 1;
    let mut i = 0;
    loop {
        if i >= exponent {
            break ();
        } else {
            result = result * base.into();
            i = i + 1;
        }
    };
    result
}
