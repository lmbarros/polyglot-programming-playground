use bevy::math::Vec2;
use interoperable_vector as iv;

fn main() {
    let vec = Vec2::new(2.0, 3.0);
    println!("Ordinary Bevy vector is {}", vec);

    let magic = iv::magic_vector(vec);
    println!("Magic Bevy vector is {}", magic);

    let dot = <bevy::prelude::Vec2 as iv::Vector2>::dot(vec, magic);
    println!("Dot product of ordinary and magic vectors is {}", dot);
}
