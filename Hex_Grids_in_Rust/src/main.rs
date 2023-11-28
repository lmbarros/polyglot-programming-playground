mod hexes;
use raylib::prelude::*;

fn main() {
    let hex_grid = hexes::FlatTopHexGrid { hex_size: 85.0 };
    // let hex_grid = hexes::PointyTopHexGrid { hex_size: 85.0 };

    draw_loop(&hex_grid);
}

const SCREEN_WIDTH: i32 = 1280;
const SCREEN_HEIGHT: i32 = 720;

fn draw_loop<G: hexes::HexGrid>(g: &G) {
    let (mut rl, thread) = raylib::init()
        .size(SCREEN_WIDTH, SCREEN_HEIGHT)
        .title("Hexes!")
        .build();

    let cam = Camera2D {
        offset: Vector2::new(SCREEN_WIDTH as f32 / 2.0, SCREEN_HEIGHT as f32 / 2.0),
        zoom: 1.0,
        ..Default::default()
    };

    while !rl.window_should_close() {
        let mut d = rl.begin_drawing(&thread);
        d.clear_background(Color::WHITE);

        let mut d2 = d.begin_mode2D(cam);

        for i in 0..6 {
            let center = Vector2::new(0.0, 0.0);
            let corner = g.hex_corner_position(center, i);
            let next_corner = g.hex_corner_position(center, (i + 1) % 6);
            d2.draw_line_v(corner, next_corner, Color::BLACK);
            d2.draw_circle_v(corner, g.hex_size() / 10.0, Color::GRAY);
            d2.draw_text(
                i.to_string().as_str(),
                corner.x as i32,
                corner.y as i32,
                25,
                Color::RED,
            )
        }
    }
}
