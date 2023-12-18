use raylib::prelude::*;

/// A hexagonal grid, rectangular in shape, with hexes arranged in a pointy-top
/// orientation, using axial coordinates.
///
/// Also, going a bit old-style here, with a vector for each property of each
/// hex, instead of a `Hex` struct. (Or is this cool again? With all the drive
/// to ECS, cache locality, etc...)
pub struct HexGrid {
    /// The number of hexes, horizontally.
    width: i32,

    /// The number of hexes, vertically.
    height: i32,

    //
    // Properties of each hex. Each of these contains width * height elements.
    //
    /// The color of each hex.
    hex_colors: Vec<Color>,

    /// An int associated with each hex. This is just to let me differentiate
    /// between hexes, for debugging purposes, and seeing what I am doing.
    hex_ints: Vec<i32>,

    //
    // Properties of each hex's birder. Each of these contains
    // (width + 1) * (height + 1) elements, with the extra row and column
    // storing data for hexes near the edges of the grid.
    //
    // Conveniently, we treat the grid as wrapping around horizontally, so the
    // extra hexes can be interpreted as being either to the east or the west of
    // the grid, as needed. Different properties of fhe same "out-of-bounds hex"
    // can even be used as both west and east of the grid, at the same time
    // (this happens on odd rows).
    /// The color of each hex's west wall.
    w_wall: Vec<Option<Color>>,

    /// The color of each hex's north-west wall.
    nw_wall: Vec<Option<Color>>,

    /// The color of each hex's north-east wall.
    ne_wall: Vec<Option<Color>>,
}

impl HexGrid {
    /// Creates a new hex grid.
    pub fn new(width: i32, height: i32) -> Self {
        assert!(width > 0, "width must be greater than 0, got {}", width);
        assert!(height > 0, "height must be greater than 0, got {}", height);

        // Per hex properties
        let size = width * height;
        let mut hex_colors = Vec::with_capacity(size as usize);
        let mut hex_ints = Vec::with_capacity(size as usize);

        for i in 0..size {
            hex_colors.push(Color::MAGENTA);
            hex_ints.push(i);
        }

        // Per border properties
        let size_ext = (width + 1) * (height + 1);
        let mut w_wall = Vec::with_capacity(size_ext as usize);
        let mut nw_wall = Vec::with_capacity(size_ext as usize);
        let mut ne_wall = Vec::with_capacity(size_ext as usize);

        for _ in 0..size_ext {
            w_wall.push(Some(Color::CHOCOLATE)); // TODO: Temp!
            nw_wall.push(Some(Color::BURLYWOOD)); // TODO: Temp!
            ne_wall.push(Some(Color::INDIGO)); // TODO: Temp!
        }

        Self {
            width,
            height,
            hex_colors,
            hex_ints,
            w_wall,
            nw_wall,
            ne_wall,
        }
    }

    /// Returns the number of hexes, horizontally.
    pub fn width(&self) -> i32 {
        self.width
    }

    /// Returns the number of hexes, vertically.
    pub fn height(&self) -> i32 {
        self.height
    }

    /// Returns the hex color at the given axial coordinates. If the coordinates
    /// are valid, will always return `Some(Color)`.
    ///
    /// Top-left hex is at (0, 0). The *q* axis grows east, and the *r* axis
    /// grows south-east.
    pub fn hex_color(&self, q: i32, r: i32) -> Option<Color> {
        if !self.are_coords_valid(q, r) {
            None
        } else {
            let index = self.hex_array_index(q, r);
            Some(self.hex_colors[index])
        }
    }

    pub fn set_hex_color(&mut self, q: i32, r: i32, color: Color) {
        if !self.are_coords_valid(q, r) {
            return;
        }

        let index = self.hex_array_index(q, r);
        self.hex_colors[index] = color;
    }

    pub fn hex_int(&self, q: i32, r: i32) -> Option<i32> {
        if !self.are_coords_valid(q, r) {
            None
        } else {
            let index = self.hex_array_index(q, r);
            Some(self.hex_ints[index])
        }
    }

    pub fn w_wall(&self, q: i32, r: i32) -> Option<Color> {
        let index = self.hex_array_index(q, r);
        self.w_wall[index]
    }

    pub fn nw_wall(&self, q: i32, r: i32) -> Option<Color> {
        let index = self.hex_array_index(q, r);
        self.nw_wall[index]
    }

    pub fn ne_wall(&self, q: i32, r: i32) -> Option<Color> {
        let index = self.hex_array_index(q, r);
        self.ne_wall[index]
    }

    /// Iterates over all valid axial coordinates in the grid.
    pub fn axial_coords(&self) -> impl Iterator<Item = (i32, i32)> {
        let w = self.width;
        let h = self.height;
        let mut i = 0;
        let mut j = -1;
        std::iter::from_fn(move || {
            j += 1;
            if j >= w {
                i += 1;
                j = 0;
            }
            if i >= h {
                None
            } else {
                let r = i;
                let q = (-i / 2) + j;
                Some((q, r))
            }
        })
    }

    /// Iterates over all "extra" axial coordinates in the grid. (Actually, over
    /// all normal hex plus the extra ones!)
    pub fn axial_coords_ext(&self) -> impl Iterator<Item = (i32, i32)> {
        let w = self.width + 1;
        let h = self.height + 1;
        let mut i = 0;
        let mut j = -1;
        std::iter::from_fn(move || {
            j += 1;

            // We don't need the extra column on the extra row.
            if i == h - 1 && j == w - 1 {
                return None;
            }

            if j >= w {
                i += 1;

                // Odd rows start with an extra hex to the west (and the same
                // extra hex appears on the wast side, too).
                j = if i & 1 == 1 { -1 } else { 0 };
            }
            let r = i;
            let q = (-i / 2) + j;
            return Some((q, r));
        })
    }

    //
    // Internal helpers
    //

    /// Checks if the given axial coordinates are valid.
    fn are_coords_valid(&self, q: i32, r: i32) -> bool {
        let r2 = r / 2;
        r >= 0 && r < self.height && q >= -r2 && q < self.width - r2
    }

    /// Returns the index where we store the hex located at the given axial
    /// coordinates.
    ///
    /// Validity of the coordinates is not checked by design (because this is
    /// also used for the "extra hexes" that go beyond the normally valid hex
    /// coordinates).
    fn hex_array_index(&self, q: i32, r: i32) -> usize {
        // r grows by 1 every row we go down.
        let y = r;

        // q grows by 1 every (jagged) column we go right, but the coordinates
        // are shifted to the left every other row.
        let r2 = r / 2;
        let x = q + r2;

        // Now we can treat our storage as a 2D array.
        (y * self.width + x) as usize
    }
}
