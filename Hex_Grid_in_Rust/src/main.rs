mod hex_grid;
use hex_grid::*;
mod render;
use raylib::prelude::*;

fn main() {
    let hex_grid = HexGrid::new(20, 13);
    let renderer = render::HexGridRenderer::new(&hex_grid, 35.0);

    draw_loop(renderer, &hex_grid);
}

const SCREEN_WIDTH: i32 = 1280;
const SCREEN_HEIGHT: i32 = 720;

fn draw_loop(renderer: render::HexGridRenderer, hex_grid: &HexGrid) {
    let (mut rl, thread) = raylib::init()
        .size(SCREEN_WIDTH, SCREEN_HEIGHT)
        .title("Hex Grid!")
        .build();

    // let cam = Camera2D {
    //     offset: Vector2::new(SCREEN_WIDTH as f32 / 2.0, SCREEN_HEIGHT as f32 / 2.0),
    //     zoom: 1.0,
    //     ..Default::default()
    // };

    while !rl.window_should_close() {
        let mut d = rl.begin_drawing(&thread);
        d.clear_background(Color::WHITE);

        // let mut d2 = d.begin_mode2D(cam);

        renderer.draw(&mut d);
    }
}
