use std::env;

fn main() {
    if env::args().len() != 3 {
        println!("Please provide two arguments: 'n' and 'algorithm'");
        return;
    }

    let n: u128 = env::args().nth(1).unwrap().parse().unwrap();
    let algorithm = env::args().nth(2).unwrap();

    match algorithm.as_str() {
        "recursive" => println!("fib({}) = {}   [{}]", n, fib_recursive(n), algorithm),
        "iterative" => println!("fib({}) = {}   [{}]", n, fib_iterative(n), algorithm),
        "closed" => println!("fib({}) = {}   [{}]", n, fib_closed(n), algorithm),
        _ => println!("Unknown algorithm: {}", algorithm),
    }
}

// The classic recursive implementation. "Bonitinha mas ordinária", as we'd say
// in Brazil.
fn fib_recursive(n: u128) -> u128 {
    if n <= 1 {
        return n;
    }

    fib_recursive(n - 1) + fib_recursive(n - 2)
}

// Straightforward iterative implementation.
fn fib_iterative(n: u128) -> u128 {
    let mut a = 0u128;
    let mut b = 1u128;

    for _ in 0..n {
        (a, b) = (b, a + b); // This is an "irrefutable pattern" in Rust.
    }

    a
}

// Closed form. Seems to be quite faster than the iterative version for large
// values of `n`. Too bad it only works fine up to n=75; after that, floating
// point precision limitations kick in. As the old joke goes, now I have
// 1.9999989 problems.
fn fib_closed(n: u128) -> u128 {
    // Can't call 5f64.sqrt() at compile-time?
    const SQRT_5: f64 = 2.2360679774997896964091736687312762354406183596115257242708972454;
    const PHI: f64 = (1f64 + SQRT_5) / 2f64;
    const PSI: f64 = -1f64 / PHI;

    ((PHI.powi(n as i32) - PSI.powi(n as i32)) / SQRT_5).round() as u128
}
