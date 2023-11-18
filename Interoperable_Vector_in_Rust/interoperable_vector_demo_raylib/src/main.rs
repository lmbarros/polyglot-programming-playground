use interoperable_vector as iv;
use raylib::math::Vector2;

fn main() {
    let vec = Vector2::new(2.0, 3.0);
    println!("Ordinary Raylib vector is [{}, {}]", vec.x, vec.y);

    let magic = iv::magic_vector(vec);
    println!("Magic Raylib vector is [{}, {}]", magic.x, magic.y);

    let dot = <raylib::math::Vector2 as iv::Vector2>::dot(vec, magic);
    println!(
        "Dot product of ordinary and magic vectors is {} (ahem)",
        dot
    );
}
