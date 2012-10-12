/**
 * Perlin's Simplex Noise over 1, 2, 3 and 4 dimensions.
 *
 * Authors: Original public-domain C code by Stefan Gustavson
 * (http://staffwww.itn.liu.se/~stegu/simplexnoise/DSOnoises.zip). D version by
 * Leandro Motta Barros.
 *
 * See_Also:
 * https://code.google.com/p/fractalterraingeneration/wiki/Simplex_Noise,
 * http://staffwww.itn.liu.se/~stegu/simplexnoise
 */

import std.math;

// LMB: This is way faster than simply calling std.math.floor() and casting to
//      an int. With DMD 2.060, using flags '-O -inline', noise generation was,
//      overall, almost 10% faster when using FastFloor() instead of
//      std.math.floor().
private pure nothrow int FastFloor(double x)
{
   return x > 0
      ? cast(int)(x)
      : cast(int)(x-1);
}



// Permutation table. This is just a random jumble of all numbers 0-255,
// repeated twice to avoid wrapping the index at 255 for each lookup.  This
// needs to be exactly the same for all instances on all platforms, so it's
// easiest to just keep it as static explicit data.  This also removes the need
// for any initialisation of this class.
//
// Note that making this an int[] instead of a char[] might make the code run
// faster on platforms with a high penalty for unaligned single byte
// addressing. Intel x86 is generally single-byte-friendly, but some other CPUs
// are faster with 4-aligned reads.  However, a char[] is smaller, which avoids
// cache trashing, and that is probably the most important aspect on most
// architectures.  This array is accessed a *lot* by the noise functions.  A
// vector-valued noise over 3D accesses it 96 times, and a float-valued 4D noise
// 64 times. We want this to fit in the cache!
private immutable ubyte[512] Perm = [
   151, 160, 137, 91, 90, 15, 131, 13, 201, 95, 96, 53, 194, 233, 7, 225, 140,
   36, 103, 30, 69, 142, 8, 99, 37, 240, 21, 10, 23, 190, 6, 148, 247, 120, 234,
   75, 0, 26, 197, 62, 94, 252, 219, 203, 117, 35, 11, 32, 57, 177, 33, 88, 237,
   149, 56, 87, 174, 20, 125, 136, 171, 168, 68, 175, 74, 165, 71, 134, 139, 48,
   27, 166, 77, 146, 158, 231, 83, 111, 229, 122, 60, 211, 133, 230, 220, 105,
   92, 41, 55, 46, 245, 40, 244, 102, 143, 54, 65, 25, 63, 161, 1, 216, 80, 73,
   209, 76, 132, 187, 208, 89, 18, 169, 200, 196, 135, 130, 116, 188, 159, 86,
   164, 100, 109, 198, 173, 186, 3, 64, 52, 217, 226, 250, 124, 123, 5, 202, 38,
   147, 118, 126, 255, 82, 85, 212, 207, 206, 59, 227, 47, 16, 58, 17, 182, 189,
   28, 42, 223, 183, 170, 213, 119, 248, 152, 2, 44, 154, 163, 70, 221, 153,
   101, 155, 167, 43, 172, 9, 129, 22, 39, 253, 19, 98, 108, 110, 79, 113, 224,
   232, 178, 185, 112, 104, 218, 246, 97, 228, 251, 34, 242, 193, 238, 210, 144,
   12, 191, 179, 162, 241, 81, 51, 145, 235, 249, 14, 239, 107, 49, 192, 214,
   31, 181, 199, 106, 157, 184, 84, 204, 176, 115, 121, 50, 45, 127, 4, 150,
   254, 138, 236, 205, 93, 222, 114, 67, 29, 24, 72, 243, 141, 128, 195, 78, 66,
   215, 61, 156, 180,
   151, 160, 137, 91, 90, 15, 131, 13, 201, 95, 96, 53, 194, 233, 7, 225, 140,
   36, 103, 30, 69, 142, 8, 99, 37, 240, 21, 10, 23, 190, 6, 148, 247, 120, 234,
   75, 0, 26, 197, 62, 94, 252, 219, 203, 117, 35, 11, 32, 57, 177, 33, 88, 237,
   149, 56, 87, 174, 20, 125, 136, 171, 168, 68, 175, 74, 165, 71, 134, 139, 48,
   27, 166, 77, 146, 158, 231, 83, 111, 229, 122, 60, 211, 133, 230, 220, 105,
   92, 41, 55, 46, 245, 40, 244, 102, 143, 54, 65, 25, 63, 161, 1, 216, 80, 73,
   209, 76, 132, 187, 208, 89, 18, 169, 200, 196, 135, 130, 116, 188, 159, 86,
   164, 100, 109, 198, 173, 186, 3, 64, 52, 217, 226, 250, 124, 123, 5, 202, 38,
   147, 118, 126, 255, 82, 85, 212, 207, 206, 59, 227, 47, 16, 58, 17, 182, 189,
   28, 42, 223, 183, 170, 213, 119, 248, 152, 2, 44, 154, 163, 70, 221, 153,
   101, 155, 167, 43, 172, 9, 129, 22, 39, 253, 19, 98, 108, 110, 79, 113, 224,
   232, 178, 185, 112, 104, 218, 246, 97, 228, 251, 34, 242, 193, 238, 210, 144,
   12, 191, 179, 162, 241, 81, 51, 145, 235, 249, 14, 239, 107, 49, 192, 214,
   31, 181, 199, 106, 157, 184, 84, 204, 176, 115, 121, 50, 45, 127, 4, 150,
   254, 138, 236, 205, 93, 222, 114, 67, 29, 24, 72, 243, 141, 128, 195, 78, 66,
   215, 61, 156, 180 ];


// Helper functions to compute gradients-dot-residualvectors (1D to 4D)
// Note that these generate gradients of more than unit length. To make
// a close match with the value range of classic Perlin noise, the final
// noise values need to be rescaled to fit nicely within [-1,1].
// (The simplex noise functions as such also have different scaling.)
// Note also that these noise functions are the most practical and useful
// signed version of Perlin noise. To return values according to the
// RenderMan specification from the SL noise() and pnoise() functions,
// the noise values need to be scaled and offset to [0,1], like this:
// float SLnoise = (SimplexNoise1234::noise(x,y,z) + 1.0) * 0.5;

private pure nothrow double Grad(int hash, double x)
{
   immutable int h = hash & 15;
   double grad = 1.0 + (h & 7); // gradient value 1.0, 2.0, ..., 8.0
   if (h & 8)
      grad = -grad; // set a random sign for the gradient
   return grad * x; // multiply the gradient with the distance
}

private pure nothrow double Grad(int hash, double x, double y)
{
   // Convert low 3 bits of hash code into 8 simple gradient directions, and
   // compute the dot product with (x,y).
   immutable int h = hash & 7;
   immutable double u = h < 4 ? x : y;
   immutable double v = h < 4 ? y : x;
   return ((h & 1) ? -u : u) + ((h & 2) ? -2.0 * v : 2.0 * v);
}

private pure nothrow double Grad(int hash, double x, double y, double z)
{
   // Convert low 4 bits of hash code into 12 simple gradient directions, and
   // compute dot product.
   immutable int h = hash & 15;
   immutable double u = h < 8 ? x : y;

   // fix repeats at h = 12 to 15
   immutable double v = h < 4 ? y : h == 12 || h == 14 ? x : z;

   return ((h & 1) ? -u : u) + ((h & 2) ? -v : v);
}

private pure nothrow double Grad(
   int hash, double x, double y, double z, double t)
{
   // Convert low 5 bits of hash code into 32 simple gradient directions, and
   // compute dot product.
   immutable int h = hash & 31;
   immutable double u = h < 24 ? x : y;
   immutable double v = h < 16 ? y : z;
   immutable double w = h < 8 ? z : t;
   return ((h & 1) ? -u : u) + ((h & 2) ? -v : v) + ((h & 4) ? -w : w);
}


// A lookup table to traverse the simplex around a given point in 4D.
// Details can be found where this table is used, in the 4D noise method.
//
// TODO: This should not be required, backport it from Bill's GLSL code!
private immutable ubyte[4][64] simplex = [
   [0, 1, 2, 3], [0, 1, 3, 2], [0, 0, 0, 0], [0, 2, 3, 1],
   [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [1, 2, 3, 0],
   [0, 2, 1, 3], [0, 0, 0, 0], [0, 3, 1, 2], [0, 3, 2, 1],
   [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [1, 3, 2, 0],
   [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0],
   [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0],
   [1, 2, 0, 3], [0, 0, 0, 0], [1, 3, 0, 2], [0, 0, 0, 0],
   [0, 0, 0, 0], [0, 0, 0, 0], [2, 3, 0, 1], [2, 3, 1, 0],
   [1, 0, 2, 3], [1, 0, 3, 2], [0, 0, 0, 0], [0, 0, 0, 0],
   [0, 0, 0, 0], [2, 0, 3, 1], [0, 0, 0, 0], [2, 1, 3, 0],
   [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0],
   [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0],
   [2, 0, 1, 3], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0],
   [3, 0, 1, 2], [3, 0, 2, 1], [0, 0, 0, 0], [3, 1, 2, 0],
   [2, 1, 0, 3], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0],
   [3, 1, 0, 2], [0, 0, 0, 0], [3, 2, 0, 1], [3, 2, 1, 0]
];


/**
 * Computes 1D simplex noise.
 * Parameters:
 *    x = The coordinate from where noise will be taken. Must be in the
 *        (int.min, int.max) range (yup, it is a floating-point number, but its
 *        range is expressed as integers).
 * Return: The noise at the requested coordinates. Normally, will be in the [0,
 *         1] range, but may occasionally be slightly out of this range. Do your
 *         own clamping if you need to be sure.
 */
double SimplexNoise(double x)
{
   immutable int i0 = FastFloor(x);
   int i1 = i0 + 1;
   immutable double x0 = x - i0;
   immutable double x1 = x0 - 1.0;
   double t1 = 1.0 - x1 * x1;
   double t0 = 1.0 - x0 * x0;

   // This never happens for the 1D case
   // if (t0 < 0.0)
   //    t0 = 0.0;
   assert(t0 >= 0.0, "Can't happen");

   t0 *= t0;
   immutable double n0 = t0 * t0 * Grad(Perm[i0 & 0xff], x0);

   // This never happens for the 1D case
   // if (t1 < 0.0)
   //    t1 = 0.0;
   assert(t1 >= 0.0, "Can't happen");

   t1 *= t1;
   immutable double n1 = t1 * t1 * Grad(Perm[i1 & 0xff], x1);

   // LMB: Originally, this was
   //         return 0.25 * (n0 + n1);
   //      but I changed it to return values in the [0, 1] range.
   return (n0 + n1 + 2.5313) * 0.20367;
}


/**
 * Computes 2D simplex noise.
 * Parameters:
 *    x = The first coordinate from where noise will be taken. Must be in the
 *        (int.min, int.max) range (yup, it is a floating-point number, but its
 *        range is expressed as integers).
 *    y = The second coordinate from where noise will be taken. Other details
 *        are similar to the x parameter.
 * Return: The noise at the requested coordinates. Normally, will be in the [0,
 *         1] range, but may occasionally be slightly out of this range. Do your
 *         own clamping if you need to be sure.
 */
double SimplexNoise(double x, double y)
{
   enum f2 = 0.5 * (sqrt(3.0) - 1.0);
   enum g2 = (3.0 - sqrt(3.0)) / 6.0;

   // Skew the input space to determine which simplex cell we're in
   immutable double s = (x + y) * f2; // hairy factor for 2D
   immutable double xs = x + s;
   immutable double ys = y + s;
   immutable int i = FastFloor(xs);
   immutable int j = FastFloor(ys);

   immutable double t = (i + j) * g2;
   immutable double xx0 = i - t;   // unskew the cell origin back to (x,y) space
   immutable double yy0 = j - t;
   immutable double x0 = x - xx0;  // the x,y distances from the cell origin
   immutable double y0 = y - yy0;

   // For the 2D case, the simplex shape is an equilateral triangle.  Determine
   // which simplex we are in.

   int i1;  // offsets for second (middle) corner...
   int j1;  // ...of simplex in (i,j) coords
   if (x0 > y0)
   {
      i1 = 1;
      j1 = 0;
   }   // lower triangle, XY order: (0,0)->(1,0)->(1,1)
   else
   {
      i1 = 0;
      j1 = 1;
   }   // upper triangle, YX order: (0,0)->(0,1)->(1,1)

   // A step of (1,0) in (i,j) means a step of (1-c,-c) in (x,y), and a step of
   // (0,1) in (i,j) means a step of (-c,1-c) in (x,y), where
   // c = ( 3 - sqrt(3)) / 6

   // offsets for middle corner in (x,y) unskewed coords
   immutable double x1 = x0 - i1 + g2;
   immutable double y1 = y0 - j1 + g2;

   // offsets for last corner in (x,y) unskewed coords
   immutable double x2 = x0 - 1.0 + 2.0 * g2;
   immutable double y2 = y0 - 1.0 + 2.0 * g2;

   // Wrap the integer indices at 256, to avoid indexing Perm[] out of bounds
   immutable int ii = i & 0xFF;
   immutable int jj = j & 0xFF;

   // Calculate the contribution from the three corners

   double n0; // noise contributions from the first corner
   double t0 = 0.5 - x0 * x0 - y0 * y0;
   if (t0 < 0.0)
   {
      n0 = 0.0;
   }
   else
   {
      t0 *= t0;
      n0 = t0 * t0 * Grad(Perm[ii + Perm[jj]], x0, y0);
   }

   double n1; // noise contributions from the second corner
   double t1 = 0.5 - x1 * x1 - y1 * y1;
   if (t1 < 0.0)
   {
      n1 = 0.0;
   }
   else
   {
      t1 *= t1;
      n1 = t1 * t1 * Grad(Perm[ii + i1 + Perm[jj + j1]], x1, y1);
   }

   double n2; // noise contributions from the third corner
   double t2 = 0.5 - x2 * x2 - y2 * y2;
   if (t2 < 0.0)
   {
      n2 = 0.0;
   }
   else
   {
      t2 *= t2;
      n2 = t2 * t2 * Grad(Perm[ii + 1 + Perm[jj + 1]], x2, y2);
   }

   // Add contributions from each corner to get the final noise value.  The
   // result is scaled to return values in the interval [-1,1].
   //
   // LMB: Used to be
   //   return 40.0 * (n0 + n1 + n2);
   // Changed to make output in the range [0, 1].
   return (n0 + n1 + n2 + 0.02213) * 22.6043;
}


/**
 * Computes 3D simplex noise.
 * Parameters:
 *    x = The first coordinate from where noise will be taken. Must be in the
 *        (int.min, int.max) range (yup, it is a floating-point number, but its
 *        range is expressed as integers).
 *    y = The second coordinate from where noise will be taken. Other details
 *        are similar to the x parameter.
 *    z = The third coordinate from where noise will be taken. Other details
 *        are similar to the x parameter.
 * Return: The noise at the requested coordinates. Normally, will be in the [0,
 *         1] range, but may occasionally be slightly out of this range. Do your
 *         own clamping if you need to be sure.
 */
double SimplexNoise(double x, double y, double z)
{
   // Simple skewing factors for the 3D case
   enum f3 = 1.0 / 3.0;
   enum g3 = 1.0 / 6.0;

   // Skew the input space to determine which simplex cell we're in

   // very nice and simple skew factor for 3D
   immutable double s = (x + y + z) * f3;
   immutable double xs = x + s;
   immutable double ys = y + s;
   immutable double zs = z + s;
   immutable int i = FastFloor(xs);
   immutable int j = FastFloor(ys);
   immutable int k = FastFloor(zs);

   immutable double t = (i + j + k) * g3;
   immutable double xx0 = i - t; // unskew the cell origin back to (x,y,z) space
   immutable double yy0 = j - t;
   immutable double zz0 = k - t;
   immutable double x0 = x - xx0; // the x,y,z distances from the cell origin
   immutable double y0 = y - yy0;
   immutable double z0 = z - zz0;

   // For the 3D case, the simplex shape is a slightly irregular tetrahedron.
   // Determine which simplex we are in.

   int i1, j1, k1;  // Offsets for second corner of simplex in (i,j,k) coords
   int i2, j2, k2;  // Offsets for third corner of simplex in (i,j,k) coords

   // This code would benefit from a backport from the GLSL version!
   if (x0 >= y0)
   {
      if (y0 >= z0)
      {
         // X Y Z order
         i1 = 1;
         j1 = 0;
         k1 = 0;
         i2 = 1;
         j2 = 1;
         k2 = 0;
      }
      else if (x0 >= z0)
      {
         // X Z Y order
         i1 = 1;
         j1 = 0;
         k1 = 0;
         i2 = 1;
         j2 = 0;
         k2 = 1;
      }
      else
      {
         // Z X Y order
         i1 = 0;
         j1 = 0;
         k1 = 1;
         i2 = 1;
         j2 = 0;
         k2 = 1;
      }
   }
   else // x0 < y0
   {
      if (y0 < z0)
      {
         // Z Y X order
         i1 = 0;
         j1 = 0;
         k1 = 1;
         i2 = 0;
         j2 = 1;
         k2 = 1;
      }
      else if (x0 < z0)
      {
         // Y Z X order
         i1 = 0;
         j1 = 1;
         k1 = 0;
         i2 = 0;
         j2 = 1;
         k2 = 1;
      }
      else
      {
         // Y X Z order
         i1 = 0;
         j1 = 1;
         k1 = 0;
         i2 = 1;
         j2 = 1;
         k2 = 0;
      }
   }

   // A step of (1,0,0) in (i,j,k) means a step of (1-c,-c,-c) in (x,y,z), a
   // step of (0,1,0) in (i,j,k) means a step of (-c,1-c,-c) in (x,y,z), and a
   // step of (0,0,1) in (i,j,k) means a step of (-c,-c,1-c) in (x,y,z), where c
   // = 1/6.

   // Offsets for second corner in (x,y,z) coords
   immutable double x1 = x0 - i1 + g3;
   immutable double y1 = y0 - j1 + g3;
   immutable double z1 = z0 - k1 + g3;

   // Offsets for third corner in (x,y,z) coords
   immutable double x2 = x0 - i2 + 2.0 * g3;
   immutable double y2 = y0 - j2 + 2.0 * g3;
   immutable double z2 = z0 - k2 + 2.0 * g3;

   // Offsets for last corner in (x,y,z) coords
   immutable double x3 = x0 - 1.0 + 3.0 * g3;
   immutable double y3 = y0 - 1.0 + 3.0 * g3;
   immutable double z3 = z0 - 1.0 + 3.0 * g3;

   // Wrap the integer indices at 256 to avoid indexing Perm[] out of bounds
   immutable int ii = i & 0xff;
   immutable int jj = j & 0xff;
   immutable int kk = k & 0xff;

   // Calculate the contribution from the four corners

   double n0; // noise contribution from the first corner.
   double t0 = 0.6 - x0 * x0 - y0 * y0 - z0 * z0;
   if (t0 < 0.0)
   {
      n0 = 0.0;
   }
   else
   {
      t0 *= t0;
      n0 = t0 * t0 * Grad(Perm[ii + Perm[jj + Perm[kk]]], x0, y0, z0);
   }

   double n1; // noise contribution from the second corner.
   double t1 = 0.6 - x1 * x1 - y1 * y1 - z1 * z1;
   if (t1 < 0.0)
   {
      n1 = 0.0;
   }
   else
   {
      t1 *= t1;
      n1 = t1
         * t1
         * Grad(Perm[ii + i1 + Perm[jj + j1 + Perm[kk + k1]]], x1, y1, z1);
   }

   double n2; // noise contribution from the third corner.
   double t2 = 0.6 - x2 * x2 - y2 * y2 - z2 * z2;
   if (t2 < 0.0)
      n2 = 0.0;
   else {
      t2 *= t2;
      n2 = t2
         * t2
         * Grad(Perm[ii + i2 + Perm[jj + j2 + Perm[kk + k2]]], x2, y2, z2);
   }

   double n3; // noise contribution from the fourth corner.
   double t3 = 0.6 - x3 * x3 - y3 * y3 - z3 * z3;
   if (t3 < 0.0)
   {
      n3 = 0.0;
   }
   else
   {
      t3 *= t3;
      n3 = t3
         * t3
         * Grad(Perm[ii + 1 + Perm[jj + 1 + Perm[kk + 1]]], x3, y3, z3);
   }

   // Add contributions from each corner to get the final noise value.
   // The result is scaled to stay just inside [-1,1]
   //
   // LMB: Used to be
   //         return 32.0 * (n0 + n1 + n2 + n3);
   //      Changed to keep output in the [0, 1] range.
   return (n0 + n1 + n2 + n3 + 0.03059) * 16.3493;
}


/**
 * Computes 4D simplex noise.
 * Parameters:
 *    x = The first coordinate from where noise will be taken. Must be in the
 *        (int.min, int.max) range (yup, it is a floating-point number, but its
 *        range is expressed as integers).
 *    y = The second coordinate from where noise will be taken. Other details
 *        are similar to the x parameter.
 *    z = The third coordinate from where noise will be taken. Other details
 *        are similar to the x parameter.
 *    w = The fourth coordinate from where noise will be taken. Other details
 *        are similar to the x parameter.
 * Return: The noise at the requested coordinates. Normally, will be in the [0,
 *         1] range, but may occasionally be slightly out of this range. Do your
 *         own clamping if you need to be sure.
 */
double SimplexNoise(double x, double y, double z, double w)
{
   // The skewing and unskewing factors are hairy again for the 4D case
   enum f4 = (sqrt(5.0) - 1.0) / 4.0;
   enum g4 = (5.0 - sqrt(5.0)) / 20.0;

   // Skew the (x,y,z,w) space to determine which cell of 24 simplices we're in
   immutable double s = (x + y + z + w) * f4; // Factor for 4D skewing
   immutable double xs = x + s;
   immutable double ys = y + s;
   immutable double zs = z + s;
   immutable double ws = w + s;
   immutable int i = FastFloor(xs);
   immutable int j = FastFloor(ys);
   immutable int k = FastFloor(zs);
   immutable int l = FastFloor(ws);

   immutable double t = (i + j + k + l) * g4; // Factor for 4D unskewing

   // Unskew the cell origin back to (x,y,z,w) space
   immutable double xx0 = i - t;
   immutable double yy0 = j - t;
   immutable double zz0 = k - t;
   immutable double ww0 = l - t;

   // The x,y,z,w distances from the cell origin
   immutable double x0 = x - xx0;
   immutable double y0 = y - yy0;
   immutable double z0 = z - zz0;
   immutable double w0 = w - ww0;

   // For the 4D case, the simplex is a 4D shape I won't even try to describe.
   // To find out which of the 24 possible simplices we're in, we need to
   // determine the magnitude ordering of x0, y0, z0 and w0.  The method below
   // is a good way of finding the ordering of x,y,z,w and then find the correct
   // traversal order for the simplex we're in.  First, six pair-wise
   // comparisons are performed between each possible pair of the four
   // coordinates, and the results are used to add up binary bits for an integer
   // index.
   immutable int c1 = (x0 > y0) ? 32 : 0;
   immutable int c2 = (x0 > z0) ? 16 : 0;
   immutable int c3 = (y0 > z0) ? 8 : 0;
   immutable int c4 = (x0 > w0) ? 4 : 0;
   immutable int c5 = (y0 > w0) ? 2 : 0;
   immutable int c6 = (z0 > w0) ? 1 : 0;
   immutable int c = c1 + c2 + c3 + c4 + c5 + c6;

   // simplex[c] is a 4-vector with the numbers 0, 1, 2 and 3 in some order.
   // Many values of c will never occur, since e.g. x>y>z>w makes x<z, y<w and
   // x<w impossible. Only the 24 indices which have non-zero entries make any
   // sense.  We use a thresholding to set the coordinates in turn from the
   // largest magnitude.  The number 3 in the "simplex" array is at the position
   // of the largest coordinate.

   // The integer offsets for the second simplex corner
   immutable int i1 = simplex[c][0] >= 3 ? 1 : 0;
   immutable int j1 = simplex[c][1] >= 3 ? 1 : 0;
   immutable int k1 = simplex[c][2] >= 3 ? 1 : 0;
   immutable int l1 = simplex[c][3] >= 3 ? 1 : 0;

   // The integer offsets for the third simplex corner
   // The number 2 in the "simplex" array is at the second largest coordinate.
   immutable int i2 = simplex[c][0] >= 2 ? 1 : 0;
   immutable int j2 = simplex[c][1] >= 2 ? 1 : 0;
   immutable int k2 = simplex[c][2] >= 2 ? 1 : 0;
   immutable int l2 = simplex[c][3] >= 2 ? 1 : 0;

   // The integer offsets for the fourth simplex corner
   // The number 1 in the "simplex" array is at the second smallest coordinate.
   immutable int i3 = simplex[c][0] >= 1 ? 1 : 0;
   immutable int j3 = simplex[c][1] >= 1 ? 1 : 0;
   immutable int k3 = simplex[c][2] >= 1 ? 1 : 0;
   immutable int l3 = simplex[c][3] >= 1 ? 1 : 0;

   // The fifth corner has all coordinate offsets = 1, so no need to look that
   // up.

   // Offsets for second corner in (x,y,z,w) coords
   immutable double x1 = x0 - i1 + g4;
   immutable double y1 = y0 - j1 + g4;
   immutable double z1 = z0 - k1 + g4;
   immutable double w1 = w0 - l1 + g4;

   // Offsets for third corner in (x,y,z,w) coords
   immutable double x2 = x0 - i2 + 2.0 * g4;
   immutable double y2 = y0 - j2 + 2.0 * g4;
   immutable double z2 = z0 - k2 + 2.0 * g4;
   immutable double w2 = w0 - l2 + 2.0 * g4;

   // Offsets for fourth corner in (x,y,z,w) coords
   immutable double x3 = x0 - i3 + 3.0 * g4;
   immutable double y3 = y0 - j3 + 3.0 * g4;
   immutable double z3 = z0 - k3 + 3.0 * g4;
   immutable double w3 = w0 - l3 + 3.0 * g4;

   // Offsets for last corner in (x,y,z,w) coords
   immutable double x4 = x0 - 1.0 + 4.0 * g4;
   immutable double y4 = y0 - 1.0 + 4.0 * g4;
   immutable double z4 = z0 - 1.0 + 4.0 * g4;
   immutable double w4 = w0 - 1.0 + 4.0 * g4;

   // Wrap the integer indices at 256, to avoid indexing Perm[] out of bounds
   immutable int ii = i & 0xFF;
   immutable int jj = j & 0xFF;
   immutable int kk = k & 0xFF;
   immutable int ll = l & 0xFF;

   // Calculate the contribution from the five corners

   // Noise contribution from the first corner
   double n0;
   double t0 = 0.6 - x0 * x0 - y0 * y0 - z0 * z0 - w0 * w0;
   if (t0 < 0.0)
   {
      n0 = 0.0;
   }
   else
   {
      t0 *= t0;
      n0 = t0
         * t0
         * Grad(Perm[ii + Perm[jj + Perm[kk + Perm[ll]]]], x0, y0, z0, w0);
   }

   // Noise contribution from the second corner
   double n1;
   double t1 = 0.6 - x1 * x1 - y1 * y1 - z1 * z1 - w1 * w1;
   if (t1 < 0.0)
   {
      n1 = 0.0;
   }
   else
   {
      t1 *= t1;
      n1 = t1
         * t1
         * Grad(Perm[ii + i1 + Perm[jj + j1 + Perm[kk + k1 + Perm[ll + l1]]]],
                x1,
                y1,
                z1,
                w1);
   }

   // Noise contribution from the third corner
   double n2;
   double t2 = 0.6 - x2 * x2 - y2 * y2 - z2 * z2 - w2 * w2;
   if (t2 < 0.0)
   {
      n2 = 0.0;
   }
   else
   {
      t2 *= t2;
      n2 = t2
         * t2
         * Grad(Perm[ii + i2 + Perm[jj + j2 + Perm[kk + k2 + Perm[ll + l2]]]],
                x2,
                y2,
                z2,
                w2);
   }

   // Noise contribution from the fourth corner
   double n3;
   double t3 = 0.6 - x3 * x3 - y3 * y3 - z3 * z3 - w3 * w3;
   if (t3 < 0.0)
   {
      n3 = 0.0;
   }
   else
   {
      t3 *= t3;
      n3 = t3
         * t3
         * Grad(Perm[ii + i3 + Perm[jj + j3 + Perm[kk + k3 + Perm[ll + l3]]]],
                x3,
                y3,
                z3,
                w3);
   }

   // Noise contribution from the fifth corner
   double n4;
   double t4 = 0.6 - x4 * x4 - y4 * y4 - z4 * z4 - w4 * w4;
   if (t4 < 0.0)
   {
      n4 = 0.0;
   }
   else
   {
      t4 *= t4;
      n4 = t4
         * t4
         * Grad(Perm[ii + 1 + Perm[jj + 1 + Perm[kk + 1 + Perm[ll + 1]]]],
                x4,
                y4,
                z4,
                w4);
   }

   // Sum up and scale the result to cover the range [-1,1]
   //
   // LMB: Used to be
   //         return 27.0 * (n0 + n1 + n2 + n3 + n4);
   //      Changed in order to make the return value be in the range [0, 1]
   return (n0 + n1 + n2 + n3 + n4 + 0.03669) * 13.6335;
}
