mod hex_grid;

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

#[derive(PartialEq, Clone, Copy)]
enum Mode {
    Hex,
    AddWall,
    RemoveWall,
}

fn main() {
    let mut hex_grid = HexGrid::new(19, 11);
    let mut mode = Mode::Hex;
    let mut color: usize = 0;

    let renderer = render::HexGridRenderer::new(35.0);

    let (mut rl, thread) = raylib::init()
        .size(SCREEN_WIDTH, SCREEN_HEIGHT)
        .title("Hex Grid!")
        .build();

    let cam = Camera2D {
        offset: Vector2::new(70.0, 70.0),
        zoom: 1.0,
        ..Default::default()
    };

    // Paint all hexes the same color.
    for (q, r) in hex_grid.axial_coords() {
        hex_grid.set_hex_color(q, r, COLORS[0]);
    }

    while !rl.window_should_close() {
        // Handle input
        let mouse_pos = rl.get_mouse_position() - cam.offset;

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

        {
            let mut d2 = d.begin_mode2D(cam);
            renderer.draw(&mut d2, &hex_grid);
            if mode == Mode::Hex {
                let (q, r) = renderer.hex_coords_at_pos(mouse_pos);
                renderer.highlight_hex(&mut d2, q, r);
            } else {
                let (q, r, v1, v2) = renderer.wall_at_pos(mouse_pos);
                renderer.highlight_wall(&mut d2, q, r, v1, v2);
            }
        }

        draw_hud(&mut d, mode, color);
    }
}

fn draw_hud<D: RaylibDraw>(d: &mut D, mode: Mode, color: usize) {
    let w = 30;
    let h = 20;

    let mode_string = format!(
        "(M)ode: {}",
        match mode {
            Mode::Hex => "Hex",
            Mode::AddWall => "Add Wall",
            Mode::RemoveWall => "Remove Wall",
        }
    );
    let font_size = 20;
    d.draw_text(
        mode_string.as_str(),
        5,
        SCREEN_HEIGHT - font_size - 5,
        font_size,
        Color::BLACK,
    );

    d.draw_text(
        "(C)olor:",
        250,
        SCREEN_HEIGHT - font_size - 5,
        font_size,
        Color::BLACK,
    );
    let x = 340;
    let y = SCREEN_HEIGHT - h - 5;
    d.draw_rectangle(x, y, w, h, COLORS[color]);
    d.draw_rectangle_lines(x, y, w, h, Color::BLACK);
}
