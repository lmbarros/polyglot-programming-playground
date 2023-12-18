use crate::hex_grid::*;

use raylib::prelude::*;

use std::time::{SystemTime, UNIX_EPOCH};

// Not just a renderer. Also a picker.
pub struct HexGridRenderer {
    hex_size: f32,
}

impl<'a> HexGridRenderer {
    pub fn new(hex_size: f32) -> Self {
        Self { hex_size }
    }

    // I don't like that here we are computing the coords manually. This is
    // client code...
    pub fn draw<D: RaylibDraw>(&self, d: &mut D, hex_grid: &HexGrid) {
        for (q, r) in hex_grid.axial_coords() {
            self.draw_hex(d, hex_grid, q, r);
        }

        for (q, r) in hex_grid.axial_coords_ext() {
            self.draw_extras(d, hex_grid, q, r);
        }
    }

    /// Returns the axial coordinates of the hex that is under the given
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
        let x = (p.x / self.hex_size) / sqrt3;
        let y = (p.y / self.hex_size) / -sqrt3;

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

    /// Returns the axial coordinates of the hex that is under the given
    /// position, plus the indices of the wall closest to that same position.
    /// These indices can be passed to `self.hex_corner_position()` to obtain
    /// the wall coordinates. The indices are sorted so that the wall segment is
    /// drawn in the clockwise direction.
    ///
    /// AKA wall-picking.
    pub fn wall_at_pos(&self, p: Vector2) -> (i32, i32, u8, u8) {
        let (q, r) = self.hex_coords_at_pos(p);
        let center = self.hex_center(q, r);

        let mut min_dist_1 = f32::MAX;
        let mut min_dist_2 = f32::MAX;
        let mut closest_1: u8 = 255;
        let mut closest_2: u8 = 255;

        for i in 0..6 {
            let corner_pos = self.hex_corner_position(center, i);
            let dist = p.distance_to(corner_pos);
            if dist < min_dist_1 {
                min_dist_2 = min_dist_1;
                closest_2 = closest_1;
                min_dist_1 = dist;
                closest_1 = i;
            } else if dist < min_dist_2 {
                min_dist_2 = dist;
                closest_2 = i;
            }
        }

        if closest_1 == 0 && closest_2 == 5 {
            (q, r, 5, 0)
        } else if closest_1 > closest_2 {
            (q, r, closest_2, closest_1)
        } else {
            (q, r, closest_1, closest_2)
        }
    }

    /// Highlights the hex at the given axial coordinates.
    pub fn highlight_hex<D: RaylibDraw>(&self, d: &mut D, q: i32, r: i32) {
        let center = self.hex_center(q, r);

        let magenta = Color::MAGENTA.color_to_hsv();
        let cyan = Color::CYAN.color_to_hsv();
        let target_hue = magenta.lerp(cyan, get_pulse(10.0)).x;
        let color = Color::color_from_hsv(target_hue, 1.0, 1.0);
        let hex_radius = self.hex_height() / 2.0;
        let highlight_radius = hex_radius + (hex_radius * 0.2 * get_pulse(5.0));
        d.draw_poly_lines(center, 6, highlight_radius, 0.0, color);
    }

    /// Highlights a wall of a hex. It will be from the hex at the given axial
    /// coordinates. And the wall will be the one from vertex `v1` to vertex
    /// `v2`.
    pub fn highlight_wall<D: RaylibDraw>(&self, d: &mut D, q: i32, r: i32, v1: u8, v2: u8) {
        let v1_pos = self.hex_corner_position(self.hex_center(q, r), v1);
        let v2_pos = self.hex_corner_position(self.hex_center(q, r), v2);

        let thickness = 7.0 + 5.0 * get_pulse(5.0);

        let magenta = Color::MAGENTA.color_to_hsv();
        let cyan = Color::CYAN.color_to_hsv();
        let target_hue = magenta.lerp(cyan, get_pulse(10.0)).x;
        let color = Color::color_from_hsv(target_hue, 1.0, 1.0).fade(0.5);

        d.draw_line_ex(v1_pos, v2_pos, thickness, color);
    }

    //
    // Rendering helpers
    //

    fn draw_hex<D: RaylibDraw>(&self, d: &mut D, hex_grid: &HexGrid, q: i32, r: i32) {
        let center = self.hex_center(q, r);
        let color = hex_grid.hex_color(q, r).unwrap_or(Color::MAGENTA);
        let int = hex_grid.hex_int(q, r).unwrap_or(-1);

        let radius = self.hex_height() / 2.0;

        d.draw_poly(center, 6, radius, 0.0, color);
        d.draw_poly_lines(center, 6, radius, 0.0, Color::DARKGRAY);
        d.draw_text(
            format!("{}", int).as_str(),
            center.x as i32,
            center.y as i32,
            20,
            Color::BLACK,
        );
    }

    fn draw_extras<D: RaylibDraw>(&self, d: &mut D, hex_grid: &HexGrid, q: i32, r: i32) {
        let center = self.hex_center(q, r);

        if let Some(color) = hex_grid.w_wall(q, r) {
            let start = self.hex_corner_position(center, 3);
            let end = self.hex_corner_position(center, 4);
            d.draw_line_ex(start, end, 6.0, color);
        }

        if let Some(color) = hex_grid.nw_wall(q, r) {
            let start = self.hex_corner_position(center, 4);
            let end = self.hex_corner_position(center, 5);
            d.draw_line_ex(start, end, 6.0, color);
        }

        if let Some(color) = hex_grid.ne_wall(q, r) {
            let start = self.hex_corner_position(center, 5);
            let end = self.hex_corner_position(center, 0);
            d.draw_line_ex(start, end, 6.0, color);
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
