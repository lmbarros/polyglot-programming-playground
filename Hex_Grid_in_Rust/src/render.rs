use crate::hex_grid::*;

use raylib::prelude::*;

use std::time::{SystemTime, UNIX_EPOCH};

// Not just a renderer. Also a picker.
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

    // I don't like that here we are computing the coords manually. This is
    // client code...
    pub fn draw<D: RaylibDraw>(&self, d: &mut D) {
        for (q, r) in self.hex_grid.axial_coords() {
            self.draw_hex(d, q, r);
        }
    }

    // Highlight the hex at the given axial coordinates.
    pub fn highlight_hex<D: RaylibDraw>(&self, d: &mut D, q: i32, r: i32) {
        let width2 = self.hex_width() / 2.0;
        let height2 = self.hex_height() / 2.0;
        let center = self.hex_center(q, r) + Vector2::new(width2, height2);

        let magenta = Color::MAGENTA.color_to_hsv();
        let cyan = Color::CYAN.color_to_hsv();
        let target_hue = magenta.lerp(cyan, get_pulse(10.0)).x;
        let color = Color::color_from_hsv(target_hue, 1.0, 1.0);
        let radius = height2 + (height2 * 0.2 * get_pulse(5.0));
        d.draw_poly_lines(center, 6, radius, 0.0, color);
    }

    /// Returns the axial coordinates of the hex that is closest to the given
    /// position.
    ///
    /// Based on [Chris Cox's
    /// code](https://www.redblobgames.com/grids/hexagons/more-pixel-to-hex.html#chris-cox),
    /// as seen on Amit's page.
    pub fn hex_coords_at_pos(&self, p: Vector2) -> (i32, i32) {
        let sqrt3 = 3.0f32.sqrt();

        // Convert to a Cartesian coordinate system in which (0,0) is the center
        // of the hex at axial coordinates (0,0), and each unit in size is equal
        // to the hex size.
        let x = ((p.x - self.hex_width() / 2.0) / self.hex_size) / sqrt3;
        let y = ((p.y - self.hex_height() / 2.0) / self.hex_size) / -sqrt3;

        // Convert from that (x,y) to (q,r)
        let t = sqrt3 * y + 1.0; // scaled y, plus phase
        let temp1 = (t + x).floor(); // (y+x) diagonal, this calc needs floor
        let temp2 = t - x; // (y-x) diagonal, no floor needed
        let temp3 = 2.0 * x + 1.0; // scaled horizontal, no floor needed, needs +1 to get correct phase
        let qf = (temp1 + temp3) / 3.0; // pseudo x with fraction
        let rf = (temp1 + temp2) / 3.0; // pseudo y with fraction
        let q = (qf).floor() as i32; // pseudo x, quantized and thus requires floor
        let r = (rf).floor() as i32; // pseudo y, quantized and thus requires floor
        (q, -r)
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

// Value between 0.0 and 1.0, pulsating, with time multiplier s.
fn get_pulse(s: f64) -> f32 {
    let now = SystemTime::now();
    let t = match now.duration_since(UNIX_EPOCH) {
        Ok(duration) => s * duration.as_secs_f64(),
        Err(_) => 0.0,
    };
    ((t.sin() + 1.0) / 2.0) as f32
}
