mod globals;
mod stuff;

fn main() {
    println!("Leandro's Number is {}!", globals::LEANDROS_NUMBER);
    println!("Inverting true gives {}!", stuff::useless::invert(true)); // ouch!
}
