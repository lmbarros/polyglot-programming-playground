mod hex_grid;
use std::fs;

use hex_grid::*;
mod render;
use raylib::prelude::*;

const COLORS: [Color; 8] = [
    Color::BLUE,
    Color::LIGHTGREEN,
    Color::DARKGREEN,
    Color::BROWN,
    Color::YELLOW,
    Color::GRAY,
    Color::WHITESMOKE,
    Color::ORANGE,
];

const SCREEN_WIDTH: i32 = 1280;
const SCREEN_HEIGHT: i32 = 720;

fn main() {
    let mut hex_grid = HexGrid::new(20, 12);
    let mut color: usize = 0;

    let renderer = render::HexGridRenderer::new(35.0);

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
        // Handle input
        let mouse_pos = rl.get_mouse_position();

        if rl.is_key_pressed(KeyboardKey::KEY_C) {
            color = (color + 1) % COLORS.len();
        }

        if rl.is_mouse_button_down(MouseButton::MOUSE_BUTTON_LEFT) {
            let (q, r) = renderer.hex_coords_at_pos(mouse_pos);
            hex_grid.set_hex_color(q, r, COLORS[color]);
        }

        // Draw!
        let mut d = rl.begin_drawing(&thread);
        d.clear_background(Color::WHITE);

        // let mut d2 = d.begin_mode2D(cam);

        renderer.draw(&mut d, &hex_grid);
        let (q, r) = renderer.hex_coords_at_pos(mouse_pos);
        renderer.highlight_hex(&mut d, q, r);
        draw_hud(&mut d, color);
    }
}

fn draw_hud<D: RaylibDraw>(d: &mut D, color: usize) {
    let w = 30;
    let h = 20;
    let x = SCREEN_WIDTH - w - 5;
    let y = SCREEN_HEIGHT - h - 5;
    d.draw_rectangle(x, y, w, h, COLORS[color]);
    d.draw_rectangle_lines(x, y, w, h, Color::BLACK);

    let font_size = 20;
    d.draw_text(
        "Mode: Hex",
        5,
        SCREEN_HEIGHT - font_size - 5,
        font_size,
        Color::BLACK,
    );
}
