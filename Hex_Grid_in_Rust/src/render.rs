use crate::hex_grid::*;

use raylib::prelude::*;

pub struct HexGridRenderer<'a> {
    hex_grid: &'a HexGrid,
    hex_size: f32,
}

impl<'a> HexGridRenderer<'a> {
    pub fn new(hex_grid: &'a HexGrid, hex_size: f32) -> Self {
        Self {
            hex_grid: hex_grid,
            hex_size,
        }
    }

    pub fn draw<D: RaylibDraw>(&self, d: &mut D) {
        for i in 0..self.hex_grid.height() {
            for j in 0..self.hex_grid.width() {
                let r = i;
                let q = (-i / 2) + j;
                self.draw_hex(d, q, r);
            }
        }

        self.draw_hex(d, 0, 0);
    }

    //
    // Rendering helpers
    //

    fn draw_hex<D: RaylibDraw>(&self, d: &mut D, q: i32, r: i32) {
        let width2 = self.hex_width() / 2.0;
        let height2 = self.hex_height() / 2.0;
        let center = self.hex_center(q, r) + Vector2::new(width2, height2);
        let color = self.hex_grid.hex_color(q, r).unwrap_or(Color::MAGENTA);
        let int = self.hex_grid.hex_int(q, r).unwrap_or(-1);

        d.draw_poly(center, 6, height2, 0.0, color);
        d.draw_poly_lines(center, 6, height2, 0.0, Color::DARKGRAY);
        for i in 0..6 {
            let p = self.hex_corner_position(center, i);
            d.draw_circle_v(p, 3.0, Color::BLACK);
            d.draw_text(
                format!("{}", int).as_str(),
                center.x as i32,
                center.y as i32,
                20,
                Color::BLACK,
            );
        }
    }

    //
    // Assorted helpers
    //

    fn hex_size(&self) -> f32 {
        self.hex_size
    }

    fn hex_width(&self) -> f32 {
        self.hex_size * 3.0f32.sqrt()
    }

    fn hex_height(&self) -> f32 {
        self.hex_size * 2.0
    }

    fn horizontal_distance(&self) -> f32 {
        self.hex_width()
    }

    fn vertical_distance(&self) -> f32 {
        self.hex_size * 3.0 / 2.0
    }

    fn hex_center(&self, q: i32, r: i32) -> Vector2 {
        let x = self.horizontal_distance() * (q as f32 + r as f32 / 2.0);
        let y = self.vertical_distance() * r as f32;
        Vector2::new(x, y)
    }

    fn hex_corner_position(&self, center: Vector2, i: u8) -> Vector2 {
        let angle = (60.0 * i as f32 - 30.0).to_radians();
        let size = self.hex_size();
        center + Vector2::new(size * angle.cos(), size * angle.sin())
    }
}
