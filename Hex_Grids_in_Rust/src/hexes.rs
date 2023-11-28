use raylib::math::Vector2;

// The HexGrid trait is meant to help defining both flat-top and pointy-top hex
// grids.
pub trait HexGrid {
    // Returns the size of an hexagon. This is the size of the outer circle
    // (i.e., the circle in which the hexagon is inscribed).
    fn hex_size(&self) -> f32;

    // Returns width of an hexagon, that is, the amount of horizontal space it
    // occupies.
    fn hex_width(&self) -> f32;

    // Returns height of an hexagon, that is, the amount of vertical space it
    // occupies.
    fn hex_height(&self) -> f32;

    // Returns the vertical distance between the centers of two adjacent
    // hexagons.
    fn vertical_distance(&self) -> f32;

    // Returns the horizontal distance between the centers of two adjacent
    // hexagons.
    fn horizontal_distance(&self) -> f32;

    // Returns the position of the `i`-th corner of the hexagon centered at
    // `center`.
    fn hex_corner_position(&self, center: Vector2, i: u8) -> Vector2;
}

pub struct FlatTopHexGrid {
    pub hex_size: f32,
}

pub struct PointyTopHexGrid {
    pub hex_size: f32,
}

impl HexGrid for FlatTopHexGrid {
    fn hex_size(&self) -> f32 {
        self.hex_size
    }

    fn hex_width(&self) -> f32 {
        self.hex_size * 2.0
    }

    fn hex_height(&self) -> f32 {
        self.hex_size * 3.0f32.sqrt()
    }

    fn horizontal_distance(&self) -> f32 {
        self.hex_size * 3.0 / 2.0
    }

    fn vertical_distance(&self) -> f32 {
        self.hex_height()
    }

    fn hex_corner_position(&self, center: Vector2, i: u8) -> Vector2 {
        let angle = (60.0 * i as f32).to_radians();
        let size = self.hex_size();
        center + Vector2::new(size * angle.cos(), size * angle.sin())
    }
}

impl HexGrid for PointyTopHexGrid {
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

    fn hex_corner_position(&self, center: Vector2, i: u8) -> Vector2 {
        let angle = (60.0 * i as f32 - 30.0).to_radians();
        let size = self.hex_size();
        center + Vector2::new(size * angle.cos(), size * angle.sin())
    }
}
