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

    // Summary of coordinate systems:
    //
    // * Offset: Basically treat the grid as a square grid, but with every other
    //   row (or column) shifted by half a square. (Incidentally, I recall some
    //   SNES games like Uncharted Waters: New Horizons actually rendering
    //   things as shifted squares -- I guess to avoid supposedly expensive
    //   transparent tile rendering.) Just use q and r instead of x and y (to
    //   differentiate between screen coordinates and grid coordinates).
    // * Cube: If a square grid has two obvious coordinates, a hexagonal grid
    //   has three (q, r, s). Of course they are not orthogonal, one is
    //   redundant. So, we enforce the constraint q + r + s = 0. A nice thing is
    //   that coordinates can be handled as vectors, so we can do things like
    //   `start_position + offset`.
    // * Axial: Same as cube, but we leave the s coordinate out (which is
    //   redundant anyway: s = -q - r). This is equivalent as slanting a square
    //   grid to make look like a rhombus. That's the easiest to visualize it.
    // * Doubled: Variation of the offset scheme. In pointy top, every movement
    //   to the right doubles the q coordinate. In flat top, every movement down
    //   doubles the r coordinate. The hexes in-between on the next row/column
    //   get the in-between values, so this makes more sense than it looks at
    //   first. Keeps the constraint `(q + r) % 2 == 0`. Apparently using this
    //   coordinate system makes it simpler to implement certain algorithms
    //   (when compared with offset, I guess).

    // Converts an axial coordinate to an offset coordinate (one with the odd
    // rows or columns shifted).
    fn axial_to_offset_odd(q: i32, r: i32) -> (i32, i32);

    // Converts an offset coordinate (one with odd rows or columns shifted) to
    // an axial coordinate.
    fn offset_odd_to_axial(col: i32, row: i32) -> (i32, i32);

    // Converts an axial coordinate to an offset coordinate (one with the even
    // rows or columns shifted).
    fn axial_to_offset_even(q: i32, r: i32) -> (i32, i32);

    // Converts an offset coordinate (one with even rows or columns shifted) to
    // an axial coordinate.
    fn offset_even_to_axial(col: i32, row: i32) -> (i32, i32);

    // Converts a cube coordinate to an offset coordinate (one with the odd rows
    // or columns shifted).
    fn cube_to_offset_odd(q: i32, r: i32, s: i32) -> (i32, i32);

    // Converts an offset coordinate (one with odd rows or columns shifted) to
    // a cube coordinate.
    fn offset_odd_to_cube(col: i32, row: i32) -> (i32, i32, i32);

    // Converts a cube coordinate to an offset coordinate (one with the even
    // rows or columns shifted).
    fn cube_to_offset_even(q: i32, r: i32, s: i32) -> (i32, i32);

    // Converts an offset coordinate (one with even rows or columns shifted) to
    // a cube coordinate.
    fn offset_even_to_cube(col: i32, row: i32) -> (i32, i32, i32);
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

    fn axial_to_offset_odd(q: i32, r: i32) -> (i32, i32) {
        let col = q;
        let row = r + (q - (q & 1)) / 2;
        (col, row)
    }

    fn offset_odd_to_axial(col: i32, row: i32) -> (i32, i32) {
        let q = col;
        let r = row - (col - (col & 1)) / 2;
        (q, r)
    }

    fn axial_to_offset_even(q: i32, r: i32) -> (i32, i32) {
        let col = q;
        let row = r + (q + (q & 1)) / 2;
        (col, row)
    }

    fn offset_even_to_axial(col: i32, row: i32) -> (i32, i32) {
        let q = col;
        let r = row - (col + (col & 1)) / 2;
        (q, r)
    }

    fn cube_to_offset_odd(q: i32, r: i32, _s: i32) -> (i32, i32) {
        let col = q;
        let row = r + (q - (q & 1)) / 2;
        (col, row)
    }

    fn offset_odd_to_cube(col: i32, row: i32) -> (i32, i32, i32) {
        let q = col;
        let r = row - (col - (col & 1)) / 2;
        (q, r, -q - r)
    }

    fn cube_to_offset_even(q: i32, r: i32, _s: i32) -> (i32, i32) {
        let col = q;
        let row = r + (q + (q & 1)) / 2;
        (col, row)
    }

    fn offset_even_to_cube(col: i32, row: i32) -> (i32, i32, i32) {
        let q = col;
        let r = row - (col + (col & 1)) / 2;
        (q, r, -q - r)
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

    fn axial_to_offset_odd(q: i32, r: i32) -> (i32, i32) {
        let col = q + (r - (r & 1)) / 2;
        let row = r;
        (col, row)
    }

    fn offset_odd_to_axial(col: i32, row: i32) -> (i32, i32) {
        let q = col - (row - (row & 1)) / 2;
        let r = row;
        (q, r)
    }

    fn axial_to_offset_even(q: i32, r: i32) -> (i32, i32) {
        let col = q + (r + (r & 1)) / 2;
        let row = r;
        (col, row)
    }

    fn offset_even_to_axial(col: i32, row: i32) -> (i32, i32) {
        let q = col - (row + (row & 1)) / 2;
        let r = row;
        (q, r)
    }

    fn cube_to_offset_odd(q: i32, r: i32, _s: i32) -> (i32, i32) {
        let col = q + (r - (r & 1)) / 2;
        let row = r;
        (col, row)
    }

    fn offset_odd_to_cube(col: i32, row: i32) -> (i32, i32, i32) {
        let q = col - (row - (row & 1)) / 2;
        let r = row;
        (q, r, -q - r)
    }

    fn cube_to_offset_even(q: i32, r: i32, _s: i32) -> (i32, i32) {
        let col = q + (r + (r & 1)) / 2;
        let row = r;
        (col, row)
    }

    fn offset_even_to_cube(col: i32, row: i32) -> (i32, i32, i32) {
        let q = col - (row + (row & 1)) / 2;
        let r = row;
        (q, r, -q - r)
    }
}
