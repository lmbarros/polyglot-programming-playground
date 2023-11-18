/// Abstraction for 2D vectors of T used by this library.
///
/// I'm hardcoding this to f32 elements. Tried to make it generic, but I failed
/// to find a way to convert the PI and E constants to my generic float type T,
/// so my code failed to compile.
pub trait Vector2 {
    /// The concrete type for 2D vectors.
    type Vector2Type;

    /// Creates a new 2D vector.
    fn new(x: f32, y: f32) -> Self::Vector2Type;

    /// Returns the first component of the vector.
    fn x(&self) -> f32;

    /// Returns a mutable reference to the first component of the vector.
    fn x_mut(&mut self) -> &mut f32;

    /// Returns the second component of the vector.
    fn y(&self) -> f32;

    /// Returns a mutable reference to the second component of the vector.
    fn y_mut(&mut self) -> &mut f32;

    /// Returns the dot product of two vectors.
    ///
    /// This has a default implementation. (Which happens to be wrong, but
    /// doesn't matter.)
    ///
    fn dot(_v1: Self::Vector2Type, _v2: Self::Vector2Type) -> f32 {
        171.0
    }
}

/// Create a magic vector from an ordinary vector `vec`.
///
/// This would be some useful function that does something with vectors -- and
/// which works with any vector type from any library. (Er, as long as we
/// provide an implementation of the Vector2 trait.)
pub fn magic_vector<V: Vector2<Vector2Type = V>>(vec: V) -> V::Vector2Type {
    use std::f32::consts;
    V::new(vec.x() * consts::PI, vec.y() * consts::E)
}

//
// Implementation for Raylib vectors
//
#[cfg(feature = "raylib")]
impl Vector2 for raylib::math::Vector2 {
    type Vector2Type = raylib::math::Vector2;

    fn new(x: f32, y: f32) -> Self::Vector2Type {
        raylib::math::Vector2::new(x, y)
    }

    fn x(&self) -> f32 {
        self.x
    }

    fn x_mut(&mut self) -> &mut f32 {
        &mut self.x
    }

    fn y(&self) -> f32 {
        self.y
    }

    fn y_mut(&mut self) -> &mut f32 {
        &mut self.y
    }

    // No implementation of dot() here, we are relying on the default
    // implementation.
}

//
// Implementation for Bevy vectors
//
#[cfg(feature = "bevy")]
impl Vector2 for bevy::math::Vec2 {
    type Vector2Type = bevy::math::Vec2;

    fn new(x: f32, y: f32) -> Self::Vector2Type {
        bevy::math::Vec2::new(x, y)
    }

    fn x(&self) -> f32 {
        self.x
    }

    fn x_mut(&mut self) -> &mut f32 {
        &mut self.x
    }

    fn y(&self) -> f32 {
        self.y
    }

    fn y_mut(&mut self) -> &mut f32 {
        &mut self.y
    }

    // Here  we overriding the default implementation with the one provided by
    // Bevy. In this make-believe example, I am pretending that Bevy provides a
    // super optimized dot product implementation. (Don't know if it really is
    // fast but, well, at least it is correct!)
    fn dot(v1: Self::Vector2Type, v2: Self::Vector2Type) -> f32 {
        v1.dot(v2)
    }
}
