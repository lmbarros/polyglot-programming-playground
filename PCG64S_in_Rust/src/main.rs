mod pcg64s;

fn main() {
    let mut rng = pcg64s::Rand::new(1234);
    for _ in 0..10 {
        println!("{}", rng.random());
    }
}
