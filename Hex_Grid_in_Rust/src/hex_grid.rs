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

    /// The color of each hex.
    hex_colors: Vec<Color>,

    /// An int associated with each hex. This is just to let me differentiate
    /// between hexes, for debugging purposes, and seeing what I am doing.
    hex_ints: Vec<i32>,
}

impl HexGrid {
    /// Creates a new hex grid.
    pub fn new(width: i32, height: i32) -> Self {
        assert!(width > 0, "width must be greater than 0, got {}", width);
        assert!(height > 0, "height must be greater than 0, got {}", height);

        let num_hexes = width * height;
        let mut hex_colors = Vec::with_capacity(num_hexes as usize);
        let mut hex_ints = Vec::with_capacity(num_hexes as usize);

        for i in 0..num_hexes {
            hex_colors.push(Color::LIGHTSLATEGRAY);
            hex_ints.push(i);
        }

        Self {
            width,
            height,
            hex_colors,
            hex_ints,
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
    /// Validity of the coordinates is expected to have been already checked
    /// at this point, so we simply `assert!()` here.
    fn hex_array_index(&self, q: i32, r: i32) -> usize {
        assert!(
            self.are_coords_valid(q, r),
            "axial coordinates ({}, {}) are invalid for a {} x {} hex grid.",
            q,
            r,
            self.width,
            self.height
        );

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