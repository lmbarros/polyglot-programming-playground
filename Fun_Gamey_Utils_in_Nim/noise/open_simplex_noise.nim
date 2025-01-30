##
## OpenSimplex noise in 2D, 3D and 4D.
##
## "Visually axis-decorrelated coherent noise", similar to Perlin's
## simplex noise, but unencumbered by patents. If you wish to know
## more details about the algorithm, please see the two original `blog
## <http://uniblock.tumblr.com/post/97868843242/noise>`_ `posts
## <http://uniblock.tumblr.com/post/99279694832/2d-and-4d-noise-too>_`
## that introduced it.
##
## **Author:** Original `public domain Java code
## <https://gist.github.com/KdotJPG/b1270127455a94ac5d19>`_ by Kurt
## Spencer. Translated to Nim by Leandro Motta Barros.
##

import math
import unsigned


#
# Assorted constants used throughout the code
#
const
  stretchConst2D = (1 / sqrt(2+1) - 1) / 2
  stretchConst3D = (1 / sqrt(3+1) - 1) / 3
  stretchConst4D = (1 / sqrt(4+1) - 1) / 4

  squishConst2D = (sqrt(2+1) - 1) / 2
  squishConst3D = (sqrt(3+1) - 1) / 3
  squishConst4D = (sqrt(4+1) - 1) / 4

  normConst2D = 47.0
  normConst3D = 103.0
  normConst4D = 30.0

  defaultSeed = 0'i64

  gradients2D = [ ##
    ## Gradients for 2D. They approximate the directions to the
    ## vertices of an octagon from the center
     5,  2,      2,  5,
    -5,  2,     -2,  5,
     5, -2,      2, -5,
    -5, -2,     -2, -5 ]

  gradients3D = [ ##
    ## Gradients for 3D. They approximate the directions to the
    ## vertices of a rhombicuboctahedron from the center, skewed so
    ## that the triangular and square facets can be inscribed inside
    ## circles of the same radius
    -11,  4,  4,     -4,  11,  4,    -4,  4,  11,
     11,  4,  4,      4,  11,  4,     4,  4,  11,
    -11, -4,  4,     -4, -11,  4,    -4, -4,  11,
     11, -4,  4,      4, -11,  4,     4, -4,  11,
    -11,  4, -4,     -4,  11, -4,    -4,  4, -11,
     11,  4, -4,      4,  11, -4,     4,  4, -11,
    -11, -4, -4,     -4, -11, -4,    -4, -4, -11,
     11, -4, -4,      4, -11, -4,     4, -4, -11 ]

  gradients4D = [ ##
    ## Gradients for 4D. They approximate the directions to the
    ## vertices of a disprismatotesseractihexadecachoron from the
    ## center, skewed so that the tetrahedral and cubic facets can be
    ## inscribed inside spheres of the same radius
     3,  1,  1,  1,    1,  3,  1,  1,    1,  1,  3,  1,    1,  1,  1,  3,
    -3,  1,  1,  1,   -1,  3,  1,  1,   -1,  1,  3,  1,   -1,  1,  1,  3,
     3, -1,  1,  1,    1, -3,  1,  1,    1, -1,  3,  1,    1, -1,  1,  3,
    -3, -1,  1,  1,   -1, -3,  1,  1,   -1, -1,  3,  1,   -1, -1,  1,  3,
     3,  1, -1,  1,    1,  3, -1,  1,    1,  1, -3,  1,    1,  1, -1,  3,
    -3,  1, -1,  1,   -1,  3, -1,  1,   -1,  1, -3,  1,   -1,  1, -1,  3,
     3, -1, -1,  1,    1, -3, -1,  1,    1, -1, -3,  1,    1, -1, -1,  3,
    -3, -1, -1,  1,   -1, -3, -1,  1,   -1, -1, -3,  1,   -1, -1, -1,  3,
     3,  1,  1, -1,    1,  3,  1, -1,    1,  1,  3, -1,    1,  1,  1, -3,
    -3,  1,  1, -1,   -1,  3,  1, -1,   -1,  1,  3, -1,   -1,  1,  1, -3,
     3, -1,  1, -1,    1, -3,  1, -1,    1, -1,  3, -1,    1, -1,  1, -3,
    -3, -1,  1, -1,   -1, -3,  1, -1,   -1, -1,  3, -1,   -1, -1,  1, -3,
     3,  1, -1, -1,    1,  3, -1, -1,    1,  1, -3, -1,    1,  1, -1, -3,
    -3,  1, -1, -1,   -1,  3, -1, -1,   -1,  1, -3, -1,   -1,  1, -1, -3,
     3, -1, -1, -1,    1, -3, -1, -1,    1, -1, -3, -1,    1, -1, -1, -3,
    -3, -1, -1, -1,   -1, -3, -1, -1,   -1, -1, -3, -1,   -1, -1, -1, -3 ]



#
# The OpenSimplexNoise type
#
type
  OpenSimplexNoise* = tuple ##
    ## The noise generator state, with shouldn't be directly touched
    ## by end users.
    perm: array[0..255, int16]
    permGradIndex3D: array[0..255, int16]



#
# Some helpers
#

proc extrapolate[T: SomeReal](self: OpenSimplexNoise,
                              xsb, ysb: int,
                              dx, dy: T): T =
  let ix = xsb and 0xFF
  let iy = (self.perm[ix] + ysb) and 0xFF
  let index = self.perm[iy] and 0x0E

  result = toFloat(gradients2D[index + 0]) * dx +
           toFloat(gradients2D[index + 1]) * dy


proc extrapolate[T: SomeReal](self: OpenSimplexNoise,
                              xsb, ysb, zsb: int,
                              dx, dy, dz: T): T =
  let ix = xsb and 0xFF
  let iy = (self.perm[ix] + ysb) and 0xFF
  let iz = (self.perm[iy] + zsb) and 0xFF
  let index = self.permGradIndex3D[iz]

  result = toFloat(gradients3D[index + 0]) * dx +
           toFloat(gradients3D[index + 1]) * dy +
           toFloat(gradients3D[index + 2]) * dz


proc extrapolate[T: SomeReal](self: OpenSimplexNoise,
                              xsb, ysb, zsb, wsb: int,
                              dx, dy, dz, dw: T): T =
  let ix = xsb and 0xFF
  let iy = (self.perm[ix] + ysb) and 0xFF
  let iz = (self.perm[iy] + zsb) and 0xFF
  let iw = (self.perm[iz] + wsb) and 0xFF
  let index = self.perm[iw] and 0xFC
  result = toFloat(gradients4D[index + 0]) * dx +
           toFloat(gradients4D[index + 1]) * dy +
           toFloat(gradients4D[index + 2]) * dz +
           toFloat(gradients4D[index + 3]) * dw



#
# The public interface
#

proc initOpenSimplexNoise*(seed: int64): OpenSimplexNoise =
  ## Creates an `OpenSimplexNoise`, initializing the internal state
  ## from a given `seed` value.

  # Initializes the class using a permutation array generated from a
  # 64-bit seed. Generates a proper permutation (i.e. doesn't merely
  # perform N successive pair swaps on a base array). Uses a simple
  # 64-bit LCG

  const
    a = 6364136223846793005'i64 # LCG multiplier
    c = 1442695040888963407'i64 # LCG increment

  var
    res: OpenSimplexNoise
    source: array[0..255, int16]
    rn = seed  # random number

  for i in countup(0, 255'i16):
    source[i] = i

  rn = rn *% a +% c
  rn = rn *% a +% c
  rn = rn *% a +% c

  for i in countdown(255, 0):
    rn = rn *% a +% c
    var r = (rn + 31) mod (i + 1)
    if r < 0:
      r += (i + 1)
    res.perm[i] = source[r]
    res.permGradIndex3D[i] = (res.perm[i] mod toInt(gradients3D.len div 3)) * 3
    source[r] = source[i]

  result = res


proc initOpenSimplexNoise*(): OpenSimplexNoise =
  ## Creates an `OpenSimplexNoise`, initializing the internal state
  ## from a default seed value.
  result = initOpenSimplexNoise(defaultSeed)


proc initOpenSimplexNoise*(perm: array[0..255, int16]): OpenSimplexNoise =
  ## Creates an `OpenSimplexNoise`, initializing the internal state
  ## from a given permutation array `perm`.
  var res: OpenSimplexNoise

  res.perm = perm
  for i in countup(0, 255):
    # Since 3D has 24 gradients, simple bitmask won't work, so
    # precompute modulo array
    res.permGradIndex3D[i] = (perm[i] mod gradients3D.len div 3) * 3

  result = res


proc eval*[T: SomeReal](self: OpenSimplexNoise, x, y: T): T =
  ## Returns the 2D noise value at coordinates (`x`, `y`).

  # Place input coordinates onto grid
  let stretchOffset = (x + y) * stretchConst2D
  let xs = x + stretchOffset
  let ys = y + stretchOffset

  # Floor to get grid coordinates of rhombus (stretched square)
  # super-cell origin
  var xsb = toInt(floor(xs))
  var ysb = toInt(floor(ys))

  # Skew out to get actual coordinates of rhombus origin. We'll need
  # these later
  let squishOffset = toFloat(xsb + ysb) * squishConst2D
  let xb = toFloat(xsb) + squishOffset
  let yb = toFloat(ysb) + squishOffset

  # Compute grid coordinates relative to rhombus origin
  let xins = xs - toFloat(xsb)
  let yins = ys - toFloat(ysb)

  # Sum those together to get a value that determines which region we're in
  let inSum = xins + yins

  # Positions relative to origin point
  var dx0 = x - xb
  var dy0 = y - yb

  # We'll be defining these inside the next block and using them afterwards
  var dx_ext, dy_ext: T
  var xsv_ext, ysv_ext: int
  var value: T = 0

  # Contribution (1,0)
  let dx1 = dx0 - 1 - squishConst2D
  let dy1 = dy0 - 0 - squishConst2D
  var attn1 = 2 - dx1 * dx1 - dy1 * dy1

  if attn1 > 0:
    attn1 *= attn1
    value += attn1 * attn1 * self.extrapolate(xsb + 1, ysb + 0, dx1, dy1)

  # Contribution (0,1)
  let dx2 = dx0 - 0 - squishConst2D
  let dy2 = dy0 - 1 - squishConst2D
  var attn2 = 2 - dx2 * dx2 - dy2 * dy2

  if attn2 > 0:
    attn2 *= attn2
    value += attn2 * attn2 * self.extrapolate(xsb + 0, ysb + 1, dx2, dy2)

  if inSum <= 1: # We're inside the triangle (2-Simplex) at (0,0)
    let zins = 1 - inSum
    if zins > xins or zins > yins: # (0,0) is one of the closest two
      if xins > yins:              # triangular vertices
        xsv_ext = xsb + 1
        ysv_ext = ysb - 1
        dx_ext = dx0 - 1
        dy_ext = dy0 + 1
      else:
        xsv_ext = xsb - 1
        ysv_ext = ysb + 1
        dx_ext = dx0 + 1
        dy_ext = dy0 - 1
    else: #  (1,0) and (0,1) are the closest two vertices
      xsv_ext = xsb + 1
      ysv_ext = ysb + 1
      dx_ext = dx0 - 1 - 2 * squishConst2D
      dy_ext = dy0 - 1 - 2 * squishConst2D

  else: # We're inside the triangle (2-Simplex) at (1,1)
    let zins = 2 - inSum
    if zins < xins or zins < yins: # (0,0) is one of the closest two
      if xins > yins:              #  triangular vertices
        xsv_ext = xsb + 2
        ysv_ext = ysb + 0
        dx_ext = dx0 - 2 - 2 * squishConst2D
        dy_ext = dy0 + 0 - 2 * squishConst2D
      else:
        xsv_ext = xsb + 0
        ysv_ext = ysb + 2
        dx_ext = dx0 + 0 - 2 * squishConst2D
        dy_ext = dy0 - 2 - 2 * squishConst2D
    else: # (1,0) and (0,1) are the closest two vertices
      dx_ext = dx0
      dy_ext = dy0
      xsv_ext = xsb
      ysv_ext = ysb

    xsb += 1
    ysb += 1
    dx0 = dx0 - 1 - 2 * squishConst2D
    dy0 = dy0 - 1 - 2 * squishConst2D

  # Contribution (0,0) or (1,1)
  var attn0 = 2 - dx0 * dx0 - dy0 * dy0
  if attn0 > 0:
    attn0 *= attn0
    value += attn0 * attn0 * self.extrapolate(xsb, ysb, dx0, dy0)

  # Extra Vertex
  var attn_ext = 2 - dx_ext * dx_ext - dy_ext * dy_ext
  if attn_ext > 0:
    attn_ext *= attn_ext
    value += attn_ext * attn_ext *
             self.extrapolate(xsv_ext, ysv_ext, dx_ext, dy_ext)

  result = value / normConst2D


proc eval*[T: SomeReal](self: OpenSimplexNoise, x, y, z: T): T =
  ## Returns the 3D noise value at coordinates (`x`, `y`, `z`).

  # Place input coordinates on simplectic honeycomb
  let stretchOffset = (x + y + z) * stretchConst3D
  let xs = x + stretchOffset
  let ys = y + stretchOffset
  let zs = z + stretchOffset

  # Floor to get simplectic honeycomb coordinates of rhombohedron
  # (stretched cube) super-cell origin
  let xsb = toInt(floor(xs))
  let ysb = toInt(floor(ys))
  let zsb = toInt(floor(zs))

  # Skew out to get actual coordinates of rhombohedron origin. We'll
  # need these later
  let squishOffset = toFloat(xsb + ysb + zsb) * squishConst3D
  let xb = toFloat(xsb) + squishOffset
  let yb = toFloat(ysb) + squishOffset
  let zb = toFloat(zsb) + squishOffset

  # Compute simplectic honeycomb coordinates relative to rhombohedral origin
  let xins = xs - toFloat(xsb)
  let yins = ys - toFloat(ysb)
  let zins = zs - toFloat(zsb)

  # Sum those together to get a value that determines which region we're in
  let inSum = xins + yins + zins

  # Positions relative to origin point
  var dx0 = x - xb
  var dy0 = y - yb
  var dz0 = z - zb

  # We'll be defining these inside the next block and using them afterwards
  var dx_ext0, dy_ext0, dz_ext0,
      dx_ext1, dy_ext1, dz_ext1: T
  var xsv_ext0, ysv_ext0, zsv_ext0,
      xsv_ext1, ysv_ext1, zsv_ext1: int
  var value: T = 0

  if inSum <= 1: # We're inside the tetrahedron (3-Simplex) at (0,0,0)
    # Determine which two of (0,0,1), (0,1,0), (1,0,0) are closest
    var aPoint = 0x01
    var aScore = xins
    var bPoint = 0x02
    var bScore = yins

    if aScore >= bScore and zins > bScore:
      bScore = zins
      bPoint = 0x04
    elif aScore < bScore and zins > aScore:
      aScore = zins
      aPoint = 0x04

    # Now we determine the two lattice points not part of the
    # tetrahedron that may contribute. This depends on the closest two
    # tetrahedral vertices, including (0,0,0)
    let wins = 1 - inSum
    if wins > aScore or wins > bScore: # (0,0,0) is one of the closest two
                                       # tetrahedral vertices

      # Our other closest vertex is the closest out of a and b
      let c = if bScore > aScore: bPoint else: aPoint

      if (c and 0x01) == 0:
        xsv_ext0 = xsb - 1
        xsv_ext1 = xsb
        dx_ext0 = dx0 + 1
        dx_ext1 = dx0
      else:
        let xsbPlusOne = xsb + 1
        xsv_ext0 = xsbPlusOne
        xsv_ext1 = xsbPlusOne
        dx_ext0 = dx0 - 1
        dx_ext1 = dx_ext0

      if (c and 0x02) == 0:
        ysv_ext0 = ysb
        ysv_ext1 = ysb
        dy_ext0 = dy0
        dy_ext1 = dy0

        if (c and 0x01) == 0:
          ysv_ext1 -= 1
          dy_ext1 += 1
        else:
          ysv_ext0 -= 1
          dy_ext0 += 1
      else:
        let ysbPlusOne = ysb + 1
        ysv_ext0 = ysbPlusOne
        ysv_ext1 = ysbPlusOne
        dy_ext0 = dy0 - 1
        dy_ext1 = dy_ext0

      if (c and 0x04) == 0:
        zsv_ext0 = zsb
        zsv_ext1 = zsb - 1
        dz_ext0 = dz0
        dz_ext1 = dz0 + 1
      else:
        let zsbPlusOne = zsb + 1
        zsv_ext0 = zsbPlusOne
        zsv_ext1 = zsbPlusOne
        let dz0MinusOne = dz0 - 1
        dz_ext0 = dz0MinusOne
        dz_ext1 = dz0MinusOne

    else: # (0,0,0) is not one of the closest two tetrahedral vertices

      let c = aPoint or bPoint # Our two extra vertices are determined by
                               # the closest two
      if (c and 0x01) == 0:
        xsv_ext0 = xsb
        xsv_ext1 = xsb - 1
        dx_ext0 = dx0 - 2 * squishConst3D
        dx_ext1 = dx0 + 1 - squishConst3D
      else:
        let xsbPlusOne = xsb + 1
        xsv_ext0 = xsbPlusOne
        xsv_ext1 = xsbPlusOne
        dx_ext0 = dx0 - 1 - 2 * squishConst3D
        dx_ext1 = dx0 - 1 - squishConst3D

      if (c and 0x02) == 0:
        ysv_ext0 = ysb
        ysv_ext1 = ysb - 1
        dy_ext0 = dy0 - 2 * squishConst3D
        dy_ext1 = dy0 + 1 - squishConst3D
      else:
        let ysbPlusOne = ysb + 1
        ysv_ext0 = ysbPlusOne
        ysv_ext1 = ysbPlusOne
        dy_ext0 = dy0 - 1 - 2 * squishConst3D
        dy_ext1 = dy0 - 1 - squishConst3D

      if (c and 0x04) == 0:
        zsv_ext0 = zsb
        zsv_ext1 = zsb - 1
        dz_ext0 = dz0 - 2 * squishConst3D
        dz_ext1 = dz0 + 1 - squishConst3D
      else:
        let zsbPlusOne = zsb + 1
        zsv_ext0 = zsbPlusOne
        zsv_ext1 = zsbPlusOne
        dz_ext0 = dz0 - 1 - 2 * squishConst3D
        dz_ext1 = dz0 - 1 - squishConst3D

    # Contribution (0,0,0)
    var attn0 = 2 - dx0 * dx0 - dy0 * dy0 - dz0 * dz0
    if attn0 > 0:
      attn0 *= attn0
      value += attn0 * attn0 *
               self.extrapolate(xsb + 0, ysb + 0, zsb + 0, dx0, dy0, dz0)

    # Contribution (1,0,0)
    let dx1 = dx0 - 1 - squishConst3D
    let dy1 = dy0 - 0 - squishConst3D
    let dz1 = dz0 - 0 - squishConst3D
    var attn1 = 2 - dx1 * dx1 - dy1 * dy1 - dz1 * dz1
    if attn1 > 0:
      attn1 *= attn1
      value += attn1 * attn1 *
               self.extrapolate(xsb + 1, ysb + 0, zsb + 0, dx1, dy1, dz1)

    # Contribution (0,1,0)
    let dx2 = dx0 - 0 - squishConst3D
    let dy2 = dy0 - 1 - squishConst3D
    let dz2 = dz1
    var attn2 = 2 - dx2 * dx2 - dy2 * dy2 - dz2 * dz2
    if attn2 > 0:
      attn2 *= attn2
      value += attn2 * attn2 *
               self.extrapolate(xsb + 0, ysb + 1, zsb + 0, dx2, dy2, dz2)

    # Contribution (0,0,1)
    let dx3 = dx2
    let dy3 = dy1
    let dz3 = dz0 - 1 - squishConst3D
    var attn3 = 2 - dx3 * dx3 - dy3 * dy3 - dz3 * dz3
    if attn3 > 0:
      attn3 *= attn3
      value += attn3 * attn3 *
               self.extrapolate(xsb + 0, ysb + 0, zsb + 1, dx3, dy3, dz3)

  elif inSum >= 2: # We're inside the tetrahedron (3-Simplex) at (1,1,1)

    # Determine which two tetrahedral vertices are the closest, out of
    # (1,1,0), (1,0,1), (0,1,1) but not (1,1,1)
    var aPoint = 0x06
    var aScore = xins
    var bPoint = 0x05
    var bScore = yins

    if aScore <= bScore and zins < bScore:
      bScore = zins
      bPoint = 0x03
    elif aScore > bScore and zins < aScore:
      aScore = zins
      aPoint = 0x03

    # Now we determine the two lattice points not part of the
    # tetrahedron that may contribute.  This depends on the closest
    # two tetrahedral vertices, including (1,1,1)
    let wins = 3 - inSum

    if wins < aScore or wins < bScore: # (1,1,1) is one of the closest two
                                       # tetrahedral vertices

      # Our other closest vertex is the closest out of a and b
      let c = if bScore < aScore:  bPoint else: aPoint

      if (c and 0x01) != 0:
        xsv_ext0 = xsb + 2
        xsv_ext1 = xsb + 1
        dx_ext0 = dx0 - 2 - 3 * squishConst3D
        dx_ext1 = dx0 - 1 - 3 * squishConst3D
      else:
        xsv_ext0 = xsb
        xsv_ext1 = xsb
        let dx0MinusThreeSquish = dx0 - 3 * squishConst3D
        dx_ext0 = dx0MinusThreeSquish
        dx_ext1 = dx0MinusThreeSquish

      if (c and 0x02) != 0:
        let ysbPlusOne = ysb + 1
        ysv_ext0 = ysbPlusOne
        ysv_ext1 = ysbPlusOne
        let dy0MinusOneMinusThreeSquish = dy0 - 1 - 3 * squishConst3D
        dy_ext0 = dy0MinusOneMinusThreeSquish
        dy_ext1 = dy0MinusOneMinusThreeSquish

        if (c and 0x01) != 0:
          ysv_ext1 += 1
          dy_ext1 -= 1
        else:
          ysv_ext0 += 1
          dy_ext0 -= 1
      else:
        ysv_ext0 = ysb
        ysv_ext1 = ysb
        let dy0MinusThreeSquish = dy0 - 3 * squishConst3D
        dy_ext0 = dy0MinusThreeSquish
        dy_ext1 = dy0MinusThreeSquish

      if (c and 0x04) != 0:
        zsv_ext0 = zsb + 1
        zsv_ext1 = zsb + 2
        dz_ext0 = dz0 - 1 - 3 * squishConst3D
        dz_ext1 = dz0 - 2 - 3 * squishConst3D
      else:
        zsv_ext0 = zsb
        zsv_ext1 = zsb
        let dz0MinusThreeSquish = dz0 - 3 * squishConst3D
        dz_ext0 = dz0MinusThreeSquish
        dz_ext1 = dz0MinusThreeSquish
    else: # (1,1,1) is not one of the closest two tetrahedral vertices

      # Our two extra vertices are determined by the closest two
      let c = aPoint and bPoint

      if (c and 0x01) != 0:
        xsv_ext0 = xsb + 1
        xsv_ext1 = xsb + 2
        dx_ext0 = dx0 - 1 - squishConst3D
        dx_ext1 = dx0 - 2 - 2 * squishConst3D
      else:
        xsv_ext0 = xsb
        xsv_ext1 = xsb
        dx_ext0 = dx0 - squishConst3D
        dx_ext1 = dx0 - 2 * squishConst3D

      if (c and 0x02) != 0:
        ysv_ext0 = ysb + 1
        ysv_ext1 = ysb + 2
        dy_ext0 = dy0 - 1 - squishConst3D
        dy_ext1 = dy0 - 2 - 2 * squishConst3D
      else:
        ysv_ext0 = ysb
        ysv_ext1 = ysb
        dy_ext0 = dy0 - squishConst3D
        dy_ext1 = dy0 - 2 * squishConst3D

      if (c and 0x04) != 0:
        zsv_ext0 = zsb + 1
        zsv_ext1 = zsb + 2
        dz_ext0 = dz0 - 1 - squishConst3D
        dz_ext1 = dz0 - 2 - 2 * squishConst3D
      else:
        zsv_ext0 = zsb
        zsv_ext1 = zsb
        dz_ext0 = dz0 - squishConst3D
        dz_ext1 = dz0 - 2 * squishConst3D

    # Contribution (1,1,0)
    let dx3 = dx0 - 1 - 2 * squishConst3D
    let dy3 = dy0 - 1 - 2 * squishConst3D
    let dz3 = dz0 - 0 - 2 * squishConst3D
    var attn3 = 2 - dx3 * dx3 - dy3 * dy3 - dz3 * dz3

    if attn3 > 0:
      attn3 *= attn3
      value += attn3 * attn3 *
               self.extrapolate(xsb + 1, ysb + 1, zsb + 0, dx3, dy3, dz3)

    # Contribution (1,0,1)
    let dx2 = dx3
    let dy2 = dy0 - 0 - 2 * squishConst3D
    let dz2 = dz0 - 1 - 2 * squishConst3D
    var attn2 = 2 - dx2 * dx2 - dy2 * dy2 - dz2 * dz2
    if attn2 > 0:
      attn2 *= attn2
      value += attn2 * attn2 *
               self.extrapolate(xsb + 1, ysb + 0, zsb + 1, dx2, dy2, dz2)

    # Contribution (0,1,1)
    let dx1 = dx0 - 0 - 2 * squishConst3D
    let dy1 = dy3
    let dz1 = dz2
    var attn1 = 2 - dx1 * dx1 - dy1 * dy1 - dz1 * dz1
    if attn1 > 0:
      attn1 *= attn1
      value += attn1 * attn1 *
               self.extrapolate(xsb + 0, ysb + 1, zsb + 1, dx1, dy1, dz1)

    # Contribution (1,1,1)
    dx0 = dx0 - 1 - 3 * squishConst3D
    dy0 = dy0 - 1 - 3 * squishConst3D
    dz0 = dz0 - 1 - 3 * squishConst3D
    var attn0 = 2 - dx0 * dx0 - dy0 * dy0 - dz0 * dz0
    if attn0 > 0:
      attn0 *= attn0
      value += attn0 * attn0 *
               self.extrapolate(xsb + 1, ysb + 1, zsb + 1, dx0, dy0, dz0)

  else: # We're inside the octahedron (Rectified 3-Simplex) in between
    var
      aScore: T
      aPoint: uint8
      aIsFurtherSide: bool
      bScore: T
      bPoint: uint8
      bIsFurtherSide: bool

    # Decide between point (0,0,1) and (1,1,0) as closest
    let p1 = xins + yins
    if p1 > 1:
      aScore = p1 - 1
      aPoint = 0x03
      aIsFurtherSide = true
    else:
      aScore = 1 - p1
      aPoint = 0x04
      aIsFurtherSide = false

    # Decide between point (0,1,0) and (1,0,1) as closest
    let p2 = xins + zins
    if p2 > 1:
      bScore = p2 - 1
      bPoint = 0x05
      bIsFurtherSide = true
    else:
      bScore = 1 - p2
      bPoint = 0x02
      bIsFurtherSide = false

    # The closest out of the two (1,0,0) and (0,1,1) will replace the
    # furthest out of the two decided above, if closer
    let p3 = yins + zins
    if p3 > 1:
      let score = p3 - 1
      if aScore <= bScore and aScore < score:
        aScore = score
        aPoint = 0x06
        aIsFurtherSide = true
      elif aScore > bScore and bScore < score:
        bScore = score
        bPoint = 0x06
        bIsFurtherSide = true
    else:
      let score = 1 - p3
      if aScore <= bScore and aScore < score:
        aScore = score
        aPoint = 0x01
        aIsFurtherSide = false
      elif aScore > bScore and bScore < score:
        bScore = score
        bPoint = 0x01
        bIsFurtherSide = false

    # Where each of the two closest points are determines how the
    # extra two vertices are calculated
    if aIsFurtherSide == bIsFurtherSide:
      if aIsFurtherSide: # Both closest points on (1,1,1) side

        # One of the two extra points is (1,1,1)
        dx_ext0 = dx0 - 1 - 3 * squishConst3D
        dy_ext0 = dy0 - 1 - 3 * squishConst3D
        dz_ext0 = dz0 - 1 - 3 * squishConst3D
        xsv_ext0 = xsb + 1
        ysv_ext0 = ysb + 1
        zsv_ext0 = zsb + 1

        # Other extra point is based on the shared axis
        let c = aPoint and bPoint
        if (c and 0x01) != 0:
          dx_ext1 = dx0 - 2 - 2 * squishConst3D
          dy_ext1 = dy0 - 2 * squishConst3D
          dz_ext1 = dz0 - 2 * squishConst3D
          xsv_ext1 = xsb + 2
          ysv_ext1 = ysb
          zsv_ext1 = zsb
        elif (c and 0x02) != 0:
          dx_ext1 = dx0 - 2 * squishConst3D
          dy_ext1 = dy0 - 2 - 2 * squishConst3D
          dz_ext1 = dz0 - 2 * squishConst3D
          xsv_ext1 = xsb
          ysv_ext1 = ysb + 2
          zsv_ext1 = zsb
        else:
          dx_ext1 = dx0 - 2 * squishConst3D
          dy_ext1 = dy0 - 2 * squishConst3D
          dz_ext1 = dz0 - 2 - 2 * squishConst3D
          xsv_ext1 = xsb
          ysv_ext1 = ysb
          zsv_ext1 = zsb + 2
      else: # Both closest points on (0,0,0) side

        # One of the two extra points is (0,0,0)
        dx_ext0 = dx0
        dy_ext0 = dy0
        dz_ext0 = dz0
        xsv_ext0 = xsb
        ysv_ext0 = ysb
        zsv_ext0 = zsb

        # Other extra point is based on the omitted axis
        let c = aPoint or bPoint
        if (c and 0x01) == 0:
          dx_ext1 = dx0 + 1 - squishConst3D
          dy_ext1 = dy0 - 1 - squishConst3D
          dz_ext1 = dz0 - 1 - squishConst3D
          xsv_ext1 = xsb - 1
          ysv_ext1 = ysb + 1
          zsv_ext1 = zsb + 1
        elif (c and 0x02) == 0:
          dx_ext1 = dx0 - 1 - squishConst3D
          dy_ext1 = dy0 + 1 - squishConst3D
          dz_ext1 = dz0 - 1 - squishConst3D
          xsv_ext1 = xsb + 1
          ysv_ext1 = ysb - 1
          zsv_ext1 = zsb + 1
        else:
          dx_ext1 = dx0 - 1 - squishConst3D
          dy_ext1 = dy0 - 1 - squishConst3D
          dz_ext1 = dz0 + 1 - squishConst3D
          xsv_ext1 = xsb + 1
          ysv_ext1 = ysb + 1
          zsv_ext1 = zsb - 1
    else: # One point on (0,0,0) side, one point on (1,1,1) side
      var c1, c2: uint8
      if aIsFurtherSide:
        c1 = aPoint
        c2 = bPoint
      else:
        c1 = bPoint
        c2 = aPoint

      # One contribution is a permutation of (1,1,-1)
      if (c1 and 0x01) == 0:
        dx_ext0 = dx0 + 1 - squishConst3D
        dy_ext0 = dy0 - 1 - squishConst3D
        dz_ext0 = dz0 - 1 - squishConst3D
        xsv_ext0 = xsb - 1
        ysv_ext0 = ysb + 1
        zsv_ext0 = zsb + 1
      elif (c1 and 0x02) == 0:
        dx_ext0 = dx0 - 1 - squishConst3D
        dy_ext0 = dy0 + 1 - squishConst3D
        dz_ext0 = dz0 - 1 - squishConst3D
        xsv_ext0 = xsb + 1
        ysv_ext0 = ysb - 1
        zsv_ext0 = zsb + 1
      else:
        dx_ext0 = dx0 - 1 - squishConst3D
        dy_ext0 = dy0 - 1 - squishConst3D
        dz_ext0 = dz0 + 1 - squishConst3D
        xsv_ext0 = xsb + 1
        ysv_ext0 = ysb + 1
        zsv_ext0 = zsb - 1

      # One contribution is a permutation of (0,0,2)
      dx_ext1 = dx0 - 2 * squishConst3D
      dy_ext1 = dy0 - 2 * squishConst3D
      dz_ext1 = dz0 - 2 * squishConst3D
      xsv_ext1 = xsb
      ysv_ext1 = ysb
      zsv_ext1 = zsb
      if (c2 and 0x01) != 0:
        dx_ext1 -= 2
        xsv_ext1 += 2
      elif (c2 and 0x02) != 0:
        dy_ext1 -= 2
        ysv_ext1 += 2
      else:
        dz_ext1 -= 2
        zsv_ext1 += 2

    # Contribution (1,0,0)
    let dx1 = dx0 - 1 - squishConst3D
    let dy1 = dy0 - 0 - squishConst3D
    let dz1 = dz0 - 0 - squishConst3D
    var attn1 = 2 - dx1 * dx1 - dy1 * dy1 - dz1 * dz1
    if attn1 > 0:
      attn1 *= attn1
      value += attn1 * attn1 *
               self.extrapolate(xsb + 1, ysb + 0, zsb + 0, dx1, dy1, dz1)

    # Contribution (0,1,0)
    let dx2 = dx0 - 0 - squishConst3D
    let dy2 = dy0 - 1 - squishConst3D
    let dz2 = dz1
    var attn2 = 2 - dx2 * dx2 - dy2 * dy2 - dz2 * dz2
    if attn2 > 0:
      attn2 *= attn2
      value += attn2 * attn2 *
               self.extrapolate(xsb + 0, ysb + 1, zsb + 0, dx2, dy2, dz2)

    # Contribution (0,0,1)
    let dx3 = dx2
    let dy3 = dy1
    let dz3 = dz0 - 1 - squishConst3D
    var attn3 = 2 - dx3 * dx3 - dy3 * dy3 - dz3 * dz3
    if attn3 > 0:
      attn3 *= attn3
      value += attn3 * attn3 *
               self.extrapolate(xsb + 0, ysb + 0, zsb + 1, dx3, dy3, dz3)

    # Contribution (1,1,0)
    let dx4 = dx0 - 1 - 2 * squishConst3D
    let dy4 = dy0 - 1 - 2 * squishConst3D
    let dz4 = dz0 - 0 - 2 * squishConst3D
    var attn4 = 2 - dx4 * dx4 - dy4 * dy4 - dz4 * dz4
    if attn4 > 0:
      attn4 *= attn4
      value += attn4 * attn4 *
               self.extrapolate(xsb + 1, ysb + 1, zsb + 0, dx4, dy4, dz4)

    # Contribution (1,0,1)
    let dx5 = dx4
    let dy5 = dy0 - 0 - 2 * squishConst3D
    let dz5 = dz0 - 1 - 2 * squishConst3D
    var attn5 = 2 - dx5 * dx5 - dy5 * dy5 - dz5 * dz5
    if attn5 > 0:
      attn5 *= attn5
      value += attn5 * attn5 *
               self.extrapolate(xsb + 1, ysb + 0, zsb + 1, dx5, dy5, dz5)

    # Contribution (0,1,1)
    let dx6 = dx0 - 0 - 2 * squishConst3D
    let dy6 = dy4
    let dz6 = dz5
    var attn6 = 2 - dx6 * dx6 - dy6 * dy6 - dz6 * dz6
    if attn6 > 0:
      attn6 *= attn6
      value += attn6 * attn6 *
               self.extrapolate(xsb + 0, ysb + 1, zsb + 1, dx6, dy6, dz6)

  # First extra vertex
  var attn_ext0 = 2 - dx_ext0 * dx_ext0 - dy_ext0 * dy_ext0 - dz_ext0 * dz_ext0
  if attn_ext0 > 0:
    attn_ext0 *= attn_ext0
    value += attn_ext0 * attn_ext0 *
             self.extrapolate(xsv_ext0, ysv_ext0, zsv_ext0,
                              dx_ext0, dy_ext0, dz_ext0)

  # Second extra vertex
  var attn_ext1 = 2 - dx_ext1 * dx_ext1 - dy_ext1 * dy_ext1 - dz_ext1 * dz_ext1
  if attn_ext1 > 0:
    attn_ext1 *= attn_ext1
    value += attn_ext1 * attn_ext1 *
             self.extrapolate(xsv_ext1, ysv_ext1, zsv_ext1,
                              dx_ext1, dy_ext1, dz_ext1)

  return value / normConst3D


proc eval*[T: SomeReal](self: OpenSimplexNoise, x, y, z, w: T): T =
  ## Returns the 4D noise value at coordinates (`x`, `y`, `z`, `w`).

  # Place input coordinates on simplectic honeycomb
  let stretchOffset = (x + y + z + w) * stretchConst4D
  let xs = x + stretchOffset
  let ys = y + stretchOffset
  let zs = z + stretchOffset
  let ws = w + stretchOffset

  # Floor to get simplectic honeycomb coordinates of rhombo-hypercube
  # super-cell origin
  var xsb = toInt(floor(xs))
  var ysb = toInt(floor(ys))
  var zsb = toInt(floor(zs))
  var wsb = toInt(floor(ws))

  # Skew out to get actual coordinates of stretched rhombo-hypercube
  # origin. We'll need these later
  let squishOffset = toFloat(xsb + ysb + zsb + wsb) * squishConst4D
  let xb = toFloat(xsb) + squishOffset
  let yb = toFloat(ysb) + squishOffset
  let zb = toFloat(zsb) + squishOffset
  let wb = toFloat(wsb) + squishOffset

  # Compute simplectic honeycomb coordinates relative to
  # rhombo-hypercube origin
  let xins = xs - toFloat(xsb)
  let yins = ys - toFloat(ysb)
  let zins = zs - toFloat(zsb)
  let wins = ws - toFloat(wsb)

  # Sum those together to get a value that determines which region we're in
  let inSum = xins + yins + zins + wins

  # Positions relative to origin point
  var dx0 = x - xb
  var dy0 = y - yb
  var dz0 = z - zb
  var dw0 = w - wb

  # We'll be defining these inside the next block and using them afterwards
  var dx_ext0, dy_ext0, dz_ext0, dw_ext0,
      dx_ext1, dy_ext1, dz_ext1, dw_ext1,
      dx_ext2, dy_ext2, dz_ext2, dw_ext2: T
  var xsv_ext0, ysv_ext0, zsv_ext0, wsv_ext0,
      xsv_ext1, ysv_ext1, zsv_ext1, wsv_ext1,
      xsv_ext2, ysv_ext2, zsv_ext2, wsv_ext2: int
  var value = 0.0

  if inSum <= 1: # We're inside the pentachoron (4-Simplex) at (0,0,0,0)

    # Determine which two of (0,0,0,1), (0,0,1,0), (0,1,0,0),
    # (1,0,0,0) are closest
    var aPoint = 0x01
    var aScore = xins
    var bPoint = 0x02
    var bScore = yins

    if aScore >= bScore and zins > bScore:
      bScore = zins
      bPoint = 0x04
    elif aScore < bScore and zins > aScore:
      aScore = zins
      aPoint = 0x04

    if aScore >= bScore and wins > bScore:
      bScore = wins
      bPoint = 0x08
    elif aScore < bScore and wins > aScore:
      aScore = wins
      aPoint = 0x08

    # Now we determine the three lattice points not part of the
    # pentachoron that may contribute.  This depends on the closest
    # two pentachoron vertices, including (0,0,0,0)
    let uins = 1 - inSum
    if uins > aScore or uins > bScore: # (0,0,0,0) is one of the closest two
                                       # pentachoron vertices

      # Our other closest vertex is the closest out of a and b
      let c = if bScore > aScore: bPoint else: aPoint
      if (c and 0x01) == 0:
        xsv_ext0 = xsb - 1
        xsv_ext1 = xsb
        xsv_ext2 = xsb
        dx_ext0 = dx0 + 1
        dx_ext1 = dx0
        dx_ext2 = dx0
      else:
        let xsbPlusOne = xsb + 1
        xsv_ext0 = xsbPlusOne
        xsv_ext1 = xsbPlusOne
        xsv_ext2 = xsbPlusOne
        let dx0MinusOne = dx0 - 1
        dx_ext0 = dx0MinusOne
        dx_ext1 = dx0MinusOne
        dx_ext2 = dx0MinusOne

      if (c and 0x02) == 0:
        ysv_ext0 = ysb
        ysv_ext1 = ysb
        ysv_ext2 = ysb
        dy_ext0 = dy0
        dy_ext1 = dy0
        dy_ext2 = dy0

        if (c and 0x01) == 0x01:
          ysv_ext0 -= 1
          dy_ext0 += 1
        else:
          ysv_ext1 -= 1
          dy_ext1 += 1

      else:
        let ysbPlusOne = ysb + 1
        ysv_ext0 = ysbPlusOne
        ysv_ext1 = ysbPlusOne
        ysv_ext2 = ysbPlusOne
        let dy0MinusOne = dy0 - 1
        dy_ext0 = dy0MinusOne
        dy_ext1 = dy0MinusOne
        dy_ext2 = dy0MinusOne

      if (c and 0x04) == 0:
        zsv_ext0 = zsb
        zsv_ext1 = zsb
        zsv_ext2 = zsb
        dz_ext0 = dz0
        dz_ext1 = dz0
        dz_ext2 = dz0

        if (c and 0x03) != 0:
          if (c and 0x03) == 0x03:
            zsv_ext0 -= 1
            dz_ext0 += 1
          else:
            zsv_ext1 -= 1
            dz_ext1 += 1
        else:
          zsv_ext2 -= 1
          dz_ext2 += 1
      else:
        let zsbPlusOne = zsb + 1
        zsv_ext0 = zsbPlusOne
        zsv_ext1 = zsbPlusOne
        zsv_ext2 = zsbPlusOne
        let dz0MinusOne = dz0 - 1
        dz_ext0 = dz0MinusOne
        dz_ext1 = dz0MinusOne
        dz_ext2 = dz0MinusOne

      if (c and 0x08) == 0:
        wsv_ext0 = wsb
        wsv_ext1 = wsb
        wsv_ext2 = wsb - 1
        dw_ext0 = dw0
        dw_ext1 = dw0
        dw_ext2 = dw0 + 1
      else:
        let wsbPlusOne = wsb + 1
        wsv_ext0 = wsbPlusOne
        wsv_ext1 = wsbPlusOne
        wsv_ext2 = wsbPlusOne
        let dw0MinusOne = dw0 - 1
        dw_ext0 = dw0MinusOne
        dw_ext1 = dw0MinusOne
        dw_ext2 = dw0MinusOne

    else: # (0,0,0,0) is not one of the closest two pentachoron vertices

      # Our three extra vertices are determined by the closest two
      let c = aPoint or bPoint

      if (c and 0x01) == 0:
        xsv_ext0 = xsb
        xsv_ext2 = xsb
        xsv_ext1 = xsb - 1
        dx_ext0 = dx0 - 2 * squishConst4D
        dx_ext1 = dx0 + 1 - squishConst4D
        dx_ext2 = dx0 - squishConst4D
      else:
        let xsbPlusOne = xsb + 1
        xsv_ext0 = xsbPlusOne
        xsv_ext1 = xsbPlusOne
        xsv_ext2 = xsbPlusOne
        dx_ext0 = dx0 - 1 - 2 * squishConst4D
        let dx0MinusOneMinusSquish = dx0 - 1 - squishConst4D
        dx_ext1 = dx0MinusOneMinusSquish
        dx_ext2 = dx0MinusOneMinusSquish

      if (c and 0x02) == 0:
        ysv_ext0 = ysb
        ysv_ext1 = ysb
        ysv_ext2 = ysb
        dy_ext0 = dy0 - 2 * squishConst4D
        let dy0MinusSquish = dy0 - squishConst4D
        dy_ext1 = dy0MinusSquish
        dy_ext2 = dy0MinusSquish

        if (c and 0x01) == 0x01:
          ysv_ext1 -= 1
          dy_ext1 += 1
        else:
          ysv_ext2 -= 1
          dy_ext2 += 1
      else:
        let ysbPlusOne = ysb + 1
        ysv_ext0 = ysbPlusOne
        ysv_ext1 = ysbPlusOne
        ysv_ext2 = ysbPlusOne
        let dy0MinusOneMinusSquish = dy0 - 1 - squishConst4D
        dy_ext0 = dy0 - 1 - 2 * squishConst4D
        dy_ext1 = dy0MinusOneMinusSquish
        dy_ext2 = dy0MinusOneMinusSquish

      if (c and 0x04) == 0:
        zsv_ext0 = zsb
        zsv_ext1 = zsb
        zsv_ext2 = zsb
        dz_ext0 = dz0 - 2 * squishConst4D
        let dz0MinusSquish = dz0 - squishConst4D
        dz_ext1 = dz0MinusSquish
        dz_ext2 = dz0MinusSquish

        if (c and 0x03) == 0x03:
          zsv_ext1 -= 1
          dz_ext1 += 1
        else:
          zsv_ext2 -= 1
          dz_ext2 += 1
      else:
        let zsbPlusOne = zsb + 1
        zsv_ext0 = zsbPlusOne
        zsv_ext1 = zsbPlusOne
        zsv_ext2 = zsbPlusOne
        dz_ext0 = dz0 - 1 - 2 * squishConst4D
        let dz0MinusOneMinusSquish = dz0 - 1 - squishConst4D
        dz_ext1 = dz0MinusOneMinusSquish
        dz_ext2 = dz0MinusOneMinusSquish

      if (c and 0x08) == 0:
        wsv_ext0 =  wsb
        wsv_ext1 = wsb
        wsv_ext2 = wsb - 1
        dw_ext0 = dw0 - 2 * squishConst4D
        dw_ext1 = dw0 - squishConst4D
        dw_ext2 = dw0 + 1 - squishConst4D
      else:
        let wsbPlusOne = wsb + 1
        wsv_ext0 = wsbPlusOne
        wsv_ext1 = wsbPlusOne
        wsv_ext2 = wsbPlusOne
        dw_ext0 = dw0 - 1 - 2 * squishConst4D
        let dw0MinusOneMinusSquish = dw0 - 1 - squishConst4D
        dw_ext1 = dw0MinusOneMinusSquish
        dw_ext2 = dw0MinusOneMinusSquish

    # Contribution (0,0,0,0)
    var attn0 = 2 - dx0 * dx0 - dy0 * dy0 - dz0 * dz0 - dw0 * dw0
    if attn0 > 0:
      attn0 *= attn0
      value += attn0 * attn0 *
               self.extrapolate(xsb+0, ysb+0, zsb+0, wsb+0, dx0, dy0, dz0, dw0)

    # Contribution (1,0,0,0)
    let dx1 = dx0 - 1 - squishConst4D
    let dy1 = dy0 - 0 - squishConst4D
    let dz1 = dz0 - 0 - squishConst4D
    let dw1 = dw0 - 0 - squishConst4D
    var attn1 = 2 - dx1 * dx1 - dy1 * dy1 - dz1 * dz1 - dw1 * dw1

    if attn1 > 0:
      attn1 *= attn1
      value += attn1 * attn1 *
               self.extrapolate(xsb+1, ysb+0, zsb+0, wsb+0, dx1, dy1, dz1, dw1)

    # Contribution (0,1,0,0)
    let dx2 = dx0 - 0 - squishConst4D
    let dy2 = dy0 - 1 - squishConst4D
    let dz2 = dz1
    let dw2 = dw1
    var attn2 = 2 - dx2 * dx2 - dy2 * dy2 - dz2 * dz2 - dw2 * dw2

    if attn2 > 0:
      attn2 *= attn2
      value += attn2 * attn2 *
               self.extrapolate(xsb+0, ysb+1, zsb+0, wsb+0, dx2, dy2, dz2, dw2)

    # Contribution (0,0,1,0)
    let dx3 = dx2
    let dy3 = dy1
    let dz3 = dz0 - 1 - squishConst4D
    let dw3 = dw1
    var attn3 = 2 - dx3 * dx3 - dy3 * dy3 - dz3 * dz3 - dw3 * dw3

    if attn3 > 0:
      attn3 *= attn3
      value += attn3 * attn3 *
               self.extrapolate(xsb+0, ysb+0, zsb+1, wsb+0, dx3, dy3, dz3, dw3)

    # Contribution (0,0,0,1)
    let dx4 = dx2
    let dy4 = dy1
    let dz4 = dz1
    let dw4 = dw0 - 1 - squishConst4D
    var attn4 = 2 - dx4 * dx4 - dy4 * dy4 - dz4 * dz4 - dw4 * dw4

    if attn4 > 0:
      attn4 *= attn4
      value += attn4 * attn4 *
               self.extrapolate(xsb+0, ysb+0, zsb+0, wsb+1, dx4, dy4, dz4, dw4)

  elif inSum >= 3: # We're inside the pentachoron (4-Simplex) at (1,1,1,1)

    # Determine which two of (1,1,1,0), (1,1,0,1), (1,0,1,1),
    # (0,1,1,1) are closest
    var aPoint = 0x0E
    var aScore = xins
    var bPoint = 0x0D
    var bScore = yins

    if aScore <= bScore and zins < bScore:
      bScore = zins
      bPoint = 0x0B
    elif aScore > bScore and zins < aScore:
      aScore = zins
      aPoint = 0x0B

    if aScore <= bScore and wins < bScore:
      bScore = wins
      bPoint = 0x07
    elif aScore > bScore and wins < aScore:
      aScore = wins
      aPoint = 0x07

    # Now we determine the three lattice points not part of the
    # pentachoron that may contribute.  This depends on the closest
    # two pentachoron vertices, including (0,0,0,0)
    let uins = 4 - inSum
    if uins < aScore or uins < bScore: # (1,1,1,1) is one of the closest
                                       # two pentachoron vertices

      # Our other closest vertex is the closest out of a and b
      let c = if bScore < aScore: bPoint else: aPoint

      if (c and 0x01) != 0:
        xsv_ext0 = xsb + 2
        let xsbPlusOne = xsb + 1
        xsv_ext1 = xsbPlusOne
        xsv_ext2 = xsbPlusOne
        dx_ext0 = dx0 - 2 - 4 * squishConst4D
        let dx0MinusOneMinusFourSquish = dx0 - 1 - 4 * squishConst4D
        dx_ext1 = dx0MinusOneMinusFourSquish
        dx_ext2 = dx0MinusOneMinusFourSquish
      else:
        xsv_ext0 = xsb
        xsv_ext1 = xsb
        xsv_ext2 = xsb
        let dx0MinusFourSquish = dx0 - 4 * squishConst4D
        dx_ext0 = dx0MinusFourSquish
        dx_ext1 = dx0MinusFourSquish
        dx_ext2 = dx0MinusFourSquish

      if (c and 0x02) != 0:
        let ysbPlusOne = ysb + 1
        ysv_ext0 = ysbPlusOne
        ysv_ext1 = ysbPlusOne
        ysv_ext2 = ysbPlusOne
        let dy0MinusOneMinusFourSquish =  dy0 - 1 - 4 * squishConst4D
        dy_ext0 = dy0MinusOneMinusFourSquish
        dy_ext1 = dy0MinusOneMinusFourSquish
        dy_ext2 = dy0MinusOneMinusFourSquish

        if (c and 0x01) != 0:
          ysv_ext1 += 1
          dy_ext1 -= 1
        else:
          ysv_ext0 += 1
          dy_ext0 -= 1
      else:
        ysv_ext0 = ysb
        ysv_ext1 = ysb
        ysv_ext2 = ysb
        let dy0MinusFourSquish = dy0 - 4 * squishConst4D
        dy_ext0 = dy0MinusFourSquish
        dy_ext1 = dy0MinusFourSquish
        dy_ext2 = dy0MinusFourSquish

      if (c and 0x04) != 0:
        let zsbPlusOne = zsb + 1
        zsv_ext0 = zsbPlusOne
        zsv_ext1 = zsbPlusOne
        zsv_ext2 = zsbPlusOne
        let dz0MinusOneMinusFourSquish = dz0 - 1 - 4 * squishConst4D
        dz_ext0 = dz0MinusOneMinusFourSquish
        dz_ext1 = dz0MinusOneMinusFourSquish
        dz_ext2 = dz0MinusOneMinusFourSquish

        if (c and 0x03) != 0x03:
          if (c and 0x03) == 0:
            zsv_ext0 += 1
            dz_ext0 -= 1
          else:
            zsv_ext1 += 1
            dz_ext1 -= 1
        else:
          zsv_ext2 += 1
          dz_ext2 -= 1
      else:
        zsv_ext0 = zsb
        zsv_ext1 = zsb
        zsv_ext2 = zsb
        let dz0MinusFourSquish = dz0 - 4 * squishConst4D
        dz_ext0 = dz0MinusFourSquish
        dz_ext1 = dz0MinusFourSquish
        dz_ext2 = dz0MinusFourSquish

      if (c and 0x08) != 0:
        let wsbPlusOne = wsb + 1
        wsv_ext0 = wsbPlusOne
        wsv_ext1 = wsbPlusOne
        wsv_ext2 = wsb + 2
        let dw0MinusOneMinusFourSquish = dw0 - 1 - 4 * squishConst4D
        dw_ext0 = dw0MinusOneMinusFourSquish
        dw_ext1 = dw0MinusOneMinusFourSquish
        dw_ext2 = dw0 - 2 - 4 * squishConst4D
      else:
        wsv_ext0 = wsb
        wsv_ext1 = wsb
        wsv_ext2 = wsb
        let dw0MinusFourSquish = dw0 - 4 * squishConst4D
        dw_ext0 = dw0MinusFourSquish
        dw_ext1 = dw0MinusFourSquish
        dw_ext2 = dw0MinusFourSquish

    else: # (1,1,1,1) is not one of the closest two pentachoron vertices

      # Our three extra vertices are determined by the closest two
      let c = aPoint and bPoint

      if (c and 0x01) != 0:
        let xsbPlusOne = xsb + 1
        xsv_ext0 = xsbPlusOne
        xsv_ext2 = xsbPlusOne
        xsv_ext1 = xsb + 2
        dx_ext0 = dx0 - 1 - 2 * squishConst4D
        dx_ext1 = dx0 - 2 - 3 * squishConst4D
        dx_ext2 = dx0 - 1 - 3 * squishConst4D
      else:
        xsv_ext0 = xsb
        xsv_ext1 = xsb
        xsv_ext2 = xsb
        dx_ext0 = dx0 - 2 * squishConst4D
        let dx0MinusThreeSquish = dx0 - 3 * squishConst4D
        dx_ext1 = dx0MinusThreeSquish
        dx_ext2 = dx0MinusThreeSquish

      if (c and 0x02) != 0:
        let ysbPlusOne = ysb + 1
        ysv_ext0 = ysbPlusOne
        ysv_ext1 = ysbPlusOne
        ysv_ext2 = ysbPlusOne
        dy_ext0 = dy0 - 1 - 2 * squishConst4D
        let dy0MinusOneMinusThreeSquish = dy0 - 1 - 3 * squishConst4D
        dy_ext1 = dy0MinusOneMinusThreeSquish
        dy_ext2 = dy0MinusOneMinusThreeSquish

        if (c and 0x01) != 0:
          ysv_ext2 += 1
          dy_ext2 -= 1
        else:
          ysv_ext1 += 1
          dy_ext1 -= 1
      else:
        ysv_ext0 = ysb
        ysv_ext1 = ysb
        ysv_ext2 = ysb
        dy_ext0 = dy0 - 2 * squishConst4D
        let dy0MinusThreeSquish = dy0 - 3 * squishConst4D
        dy_ext1 = dy0MinusThreeSquish
        dy_ext2 = dy0MinusThreeSquish

      if (c and 0x04) != 0:
        let zsbPlusOne = zsb + 1
        zsv_ext0 = zsbPlusOne
        zsv_ext1 = zsbPlusOne
        zsv_ext2 = zsbPlusOne
        dz_ext0 = dz0 - 1 - 2 * squishConst4D
        let dz0MinusOneMinusThreeSquish = dz0 - 1 - 3 * squishConst4D
        dz_ext1 = dz0MinusOneMinusThreeSquish
        dz_ext2 = dz0MinusOneMinusThreeSquish

        if (c and 0x03) != 0:
          zsv_ext2 += 1
          dz_ext2 -= 1
        else:
          zsv_ext1 += 1
          dz_ext1 -= 1
      else:
        zsv_ext0 = zsb
        zsv_ext1 = zsb
        zsv_ext2 = zsb
        dz_ext0 = dz0 - 2 * squishConst4D
        let dz0MinusThreeSquish = dz0 - 3 * squishConst4D
        dz_ext1 = dz0MinusThreeSquish
        dz_ext2 = dz0MinusThreeSquish

      if (c and 0x08) != 0:
        let wsbPlusOne = wsb + 1
        wsv_ext0 = wsbPlusOne
        wsv_ext1 = wsbPlusOne
        wsv_ext2 = wsb + 2
        dw_ext0 = dw0 - 1 - 2 * squishConst4D
        dw_ext1 = dw0 - 1 - 3 * squishConst4D
        dw_ext2 = dw0 - 2 - 3 * squishConst4D
      else:
        wsv_ext0 = wsb
        wsv_ext1 = wsb
        wsv_ext2 = wsb
        dw_ext0 = dw0 - 2 * squishConst4D
        let dw0MinusThreeSquish = dw0 - 3 * squishConst4D
        dw_ext1 = dw0MinusThreeSquish
        dw_ext2 = dw0MinusThreeSquish

    # Contribution (1,1,1,0)
    let dx4 = dx0 - 1 - 3 * squishConst4D
    let dy4 = dy0 - 1 - 3 * squishConst4D
    let dz4 = dz0 - 1 - 3 * squishConst4D
    let dw4 = dw0 - 3 * squishConst4D
    var attn4 = 2 - dx4 * dx4 - dy4 * dy4 - dz4 * dz4 - dw4 * dw4

    if attn4 > 0:
      attn4 *= attn4
      value += attn4 * attn4 *
               self.extrapolate(xsb+1, ysb+1, zsb+1, wsb+0, dx4, dy4, dz4, dw4)

    # Contribution (1,1,0,1)
    let dx3 = dx4
    let dy3 = dy4
    let dz3 = dz0 - 3 * squishConst4D
    let dw3 = dw0 - 1 - 3 * squishConst4D
    var attn3 = 2 - dx3 * dx3 - dy3 * dy3 - dz3 * dz3 - dw3 * dw3

    if attn3 > 0:
      attn3 *= attn3
      value += attn3 * attn3 *
               self.extrapolate(xsb+1, ysb+1, zsb+0, wsb+1, dx3, dy3, dz3, dw3)

    # Contribution (1,0,1,1)
    let dx2 = dx4
    let dy2 = dy0 - 3 * squishConst4D
    let dz2 = dz4
    let dw2 = dw3
    var attn2 = 2 - dx2 * dx2 - dy2 * dy2 - dz2 * dz2 - dw2 * dw2

    if attn2 > 0:
      attn2 *= attn2
      value += attn2 * attn2 *
               self.extrapolate(xsb+1, ysb+0, zsb+1, wsb+1, dx2, dy2, dz2, dw2)

    # Contribution (0,1,1,1)
    let dx1 = dx0 - 3 * squishConst4D
    let dz1 = dz4
    let dy1 = dy4
    let dw1 = dw3
    var attn1 = 2 - dx1 * dx1 - dy1 * dy1 - dz1 * dz1 - dw1 * dw1

    if attn1 > 0:
      attn1 *= attn1
      value += attn1 * attn1 *
               self.extrapolate(xsb+0, ysb+1, zsb+1, wsb+1, dx1, dy1, dz1, dw1)

    # Contribution (1,1,1,1)
    dx0 = dx0 - 1 - 4 * squishConst4D
    dy0 = dy0 - 1 - 4 * squishConst4D
    dz0 = dz0 - 1 - 4 * squishConst4D
    dw0 = dw0 - 1 - 4 * squishConst4D
    var attn0 = 2 - dx0 * dx0 - dy0 * dy0 - dz0 * dz0 - dw0 * dw0

    if attn0 > 0:
      attn0 *= attn0
      value += attn0 * attn0 *
               self.extrapolate(xsb+1, ysb+1, zsb+1, wsb+1, dx0, dy0, dz0, dw0)

  elif inSum <= 2: # We're inside the first dispentachoron (Rectified 4-Simplex)
    var aScore, bScore: T
    var aPoint, bPoint: uint8
    var aIsBiggerSide = true
    var bIsBiggerSide = true

    # Decide between (1,1,0,0) and (0,0,1,1)
    if xins + yins > zins + wins:
      aScore = xins + yins
      aPoint = 0x03
    else:
      aScore = zins + wins
      aPoint = 0x0C

    # Decide between (1,0,1,0) and (0,1,0,1)
    if xins + zins > yins + wins:
      bScore = xins + zins
      bPoint = 0x05
    else:
      bScore = yins + wins
      bPoint = 0x0A

    # Closer between (1,0,0,1) and (0,1,1,0) will replace the further
    # of a and b, if closer
    if xins + wins > yins + zins:
      let score = xins + wins

      if aScore >= bScore and score > bScore:
        bScore = score
        bPoint = 0x09
      elif aScore < bScore and score > aScore:
        aScore = score
        aPoint = 0x09
    else:
      let score = yins + zins

      if aScore >= bScore and score > bScore:
        bScore = score
        bPoint = 0x06
      elif aScore < bScore and score > aScore:
        aScore = score
        aPoint = 0x06

    # Decide if (1,0,0,0) is closer
    let p1 = 2 - inSum + xins

    if aScore >= bScore and p1 > bScore:
      bScore = p1
      bPoint = 0x01
      bIsBiggerSide = false
    elif aScore < bScore and p1 > aScore:
      aScore = p1
      aPoint = 0x01
      aIsBiggerSide = false

    # Decide if (0,1,0,0) is closer
    let p2 = 2 - inSum + yins

    if aScore >= bScore and p2 > bScore:
      bScore = p2
      bPoint = 0x02
      bIsBiggerSide = false
    elif aScore < bScore and p2 > aScore:
      aScore = p2
      aPoint = 0x02
      aIsBiggerSide = false

    # Decide if (0,0,1,0) is closer
    let p3 = 2 - inSum + zins

    if aScore >= bScore and p3 > bScore:
      bScore = p3
      bPoint = 0x04
      bIsBiggerSide = false
    elif aScore < bScore and p3 > aScore:
      aScore = p3
      aPoint = 0x04
      aIsBiggerSide = false

    # Decide if (0,0,0,1) is closer
    let p4 = 2 - inSum + wins

    if aScore >= bScore and p4 > bScore:
      bScore = p4
      bPoint = 0x08
      bIsBiggerSide = false
    elif aScore < bScore and p4 > aScore:
      aScore = p4
      aPoint = 0x08
      aIsBiggerSide = false

    # Where each of the two closest points are determines how the
    # extra three vertices are calculated
    if aIsBiggerSide == bIsBiggerSide:
      if aIsBiggerSide: # Both closest points on the bigger side
        let c1 = aPoint or bPoint
        let c2 = aPoint and bPoint

        if (c1 and 0x01) == 0:
          xsv_ext0 = xsb
          xsv_ext1 = xsb - 1
          dx_ext0 = dx0 - 3 * squishConst4D
          dx_ext1 = dx0 + 1 - 2 * squishConst4D
        else:
          let xsbPlusOne = xsb + 1
          xsv_ext0 = xsbPlusOne
          xsv_ext1 = xsbPlusOne
          dx_ext0 = dx0 - 1 - 3 * squishConst4D
          dx_ext1 = dx0 - 1 - 2 * squishConst4D

        if (c1 and 0x02) == 0:
          ysv_ext0 = ysb
          ysv_ext1 = ysb - 1
          dy_ext0 = dy0 - 3 * squishConst4D
          dy_ext1 = dy0 + 1 - 2 * squishConst4D
        else:
          let ysbPlusOne = ysb + 1
          ysv_ext0 = ysbPlusOne
          ysv_ext1 = ysbPlusOne
          dy_ext0 = dy0 - 1 - 3 * squishConst4D
          dy_ext1 = dy0 - 1 - 2 * squishConst4D

        if (c1 and 0x04) == 0:
          zsv_ext0 = zsb
          zsv_ext1 = zsb - 1
          dz_ext0 = dz0 - 3 * squishConst4D
          dz_ext1 = dz0 + 1 - 2 * squishConst4D
        else:
          let zsbPlusOne = zsb + 1
          zsv_ext0 = zsbPlusOne
          zsv_ext1 = zsbPlusOne
          dz_ext0 = dz0 - 1 - 3 * squishConst4D
          dz_ext1 = dz0 - 1 - 2 * squishConst4D

        if (c1 and 0x08) == 0:
          wsv_ext0 = wsb
          wsv_ext1 = wsb - 1
          dw_ext0 = dw0 - 3 * squishConst4D
          dw_ext1 = dw0 + 1 - 2 * squishConst4D
        else:
          let wsbPlusOne = wsb + 1
          wsv_ext0 = wsbPlusOne
          wsv_ext1 = wsbPlusOne
          dw_ext0 = dw0 - 1 - 3 * squishConst4D
          dw_ext1 = dw0 - 1 - 2 * squishConst4D

        # One combination is a permutation of (0,0,0,2) based on c2
        xsv_ext2 = xsb
        ysv_ext2 = ysb
        zsv_ext2 = zsb
        wsv_ext2 = wsb
        dx_ext2 = dx0 - 2 * squishConst4D
        dy_ext2 = dy0 - 2 * squishConst4D
        dz_ext2 = dz0 - 2 * squishConst4D
        dw_ext2 = dw0 - 2 * squishConst4D

        if (c2 and 0x01) != 0:
          xsv_ext2 += 2
          dx_ext2 -= 2
        elif (c2 and 0x02) != 0:
          ysv_ext2 += 2
          dy_ext2 -= 2
        elif (c2 and 0x04) != 0:
          zsv_ext2 += 2
          dz_ext2 -= 2
        else:
          wsv_ext2 += 2
          dw_ext2 -= 2

      else: # Both closest points on the smaller side

        # One of the two extra points is (0,0,0,0)
        xsv_ext2 = xsb
        ysv_ext2 = ysb
        zsv_ext2 = zsb
        wsv_ext2 = wsb
        dx_ext2 = dx0
        dy_ext2 = dy0
        dz_ext2 = dz0
        dw_ext2 = dw0

        # Other two points are based on the omitted axes
        let c = aPoint or bPoint

        if (c and 0x01) == 0:
          xsv_ext0 = xsb - 1
          xsv_ext1 = xsb
          dx_ext0 = dx0 + 1 - squishConst4D
          dx_ext1 = dx0 - squishConst4D
        else:
          let xsbPlusOne = xsb + 1
          xsv_ext0 = xsbPlusOne
          xsv_ext1 = xsbPlusOne
          let dx0MinusOneMinusSquish = dx0 - 1 - squishConst4D
          dx_ext0 = dx0MinusOneMinusSquish
          dx_ext1 = dx0MinusOneMinusSquish

        if (c and 0x02) == 0:
          ysv_ext0 = ysb
          ysv_ext1 = ysb
          let dy0MinusSquish = dy0 - squishConst4D
          dy_ext0 = dy0MinusSquish
          dy_ext1 = dy0MinusSquish

          if (c and 0x01) == 0x01:
            ysv_ext0 -= 1
            dy_ext0 += 1
          else:
            ysv_ext1 -= 1
            dy_ext1 += 1
        else:
          let ysbPlusOne = ysb + 1
          ysv_ext0 = ysbPlusOne
          ysv_ext1 = ysbPlusOne
          let dy0MinusOneMinusSquish = dy0 - 1 - squishConst4D
          dy_ext0 = dy0MinusOneMinusSquish
          dy_ext1 = dy0MinusOneMinusSquish

        if (c and 0x04) == 0:
          zsv_ext0 = zsb
          zsv_ext1 = zsb
          let dz0MinusSquish = dz0 - squishConst4D
          dz_ext0 = dz0MinusSquish
          dz_ext1 = dz0MinusSquish

          if (c and 0x03) == 0x03:
            zsv_ext0 -= 1
            dz_ext0 += 1
          else:
            zsv_ext1 -= 1
            dz_ext1 += 1
        else:
          let zsbPlusOne = zsb + 1
          zsv_ext0 = zsbPlusOne
          zsv_ext1 = zsbPlusOne
          let dz0MinusOneMinusSquish = dz0 - 1 - squishConst4D
          dz_ext0 = dz0MinusOneMinusSquish
          dz_ext1 = dz0MinusOneMinusSquish

        if (c and 0x08) == 0:
          wsv_ext0 = wsb
          wsv_ext1 = wsb - 1
          dw_ext0 = dw0 - squishConst4D
          dw_ext1 = dw0 + 1 - squishConst4D
        else:
          let wsbPlusOne = wsb + 1
          wsv_ext0 = wsbPlusOne
          wsv_ext1 = wsbPlusOne
          let dw0MinusOneMinusSquish = dw0 - 1 - squishConst4D
          dw_ext0 = dw0MinusOneMinusSquish
          dw_ext1 = dw0MinusOneMinusSquish

    else: # One point on each "side"
      var c1, c2: uint8
      if aIsBiggerSide:
        c1 = aPoint
        c2 = bPoint
      else:
        c1 = bPoint
        c2 = aPoint

      # Two contributions are the bigger-sided point with each 0
      # replaced with -1
      if (c1 and 0x01) == 0:
        xsv_ext0 = xsb - 1
        xsv_ext1 = xsb
        dx_ext0 = dx0 + 1 - squishConst4D
        dx_ext1 = dx0 - squishConst4D
      else:
        let xsbPlusOne = xsb + 1
        xsv_ext0 = xsbPlusOne
        xsv_ext1 = xsbPlusOne
        let dx0MinusOneMinusSquish = dx0 - 1 - squishConst4D
        dx_ext0 = dx0MinusOneMinusSquish
        dx_ext1 = dx0MinusOneMinusSquish

      if (c1 and 0x02) == 0:
        ysv_ext0 = ysb
        ysv_ext1 = ysb
        let dy0MinusSquish = dy0 - squishConst4D
        dy_ext0 = dy0MinusSquish
        dy_ext1 = dy0MinusSquish

        if (c1 and 0x01) == 0x01:
          ysv_ext0 -= 1
          dy_ext0 += 1
        else:
          ysv_ext1 -= 1
          dy_ext1 += 1
      else:
        let ysbPlusOne = ysb + 1
        ysv_ext0 = ysbPlusOne
        ysv_ext1 = ysbPlusOne
        let dy0MinusOneMinusSquish = dy0 - 1 - squishConst4D
        dy_ext0 = dy0MinusOneMinusSquish
        dy_ext1 = dy0MinusOneMinusSquish

      if (c1 and 0x04) == 0:
        zsv_ext0 = zsb
        zsv_ext1 = zsb
        let dz0MinusSquish = dz0 - squishConst4D
        dz_ext0 = dz0MinusSquish
        dz_ext1 = dz0MinusSquish

        if (c1 and 0x03) == 0x03:
          zsv_ext0 -= 1
          dz_ext0 += 1
        else:
          zsv_ext1 -= 1
          dz_ext1 += 1
      else:
        let zsbPlusOne = zsb + 1
        zsv_ext0 = zsbPlusOne
        zsv_ext1 = zsbPlusOne
        let dz0MinusOneMinusSquish = dz0 - 1 - squishConst4D
        dz_ext0 = dz0MinusOneMinusSquish
        dz_ext1 = dz0MinusOneMinusSquish

      if (c1 and 0x08) == 0:
        wsv_ext0 = wsb
        wsv_ext1 = wsb - 1
        dw_ext0 = dw0 - squishConst4D
        dw_ext1 = dw0 + 1 - squishConst4D
      else:
        let wsbPlusOne = wsb + 1
        wsv_ext0 = wsbPlusOne
        wsv_ext1 = wsbPlusOne
        let dw0MinusOneMinusSquish = dw0 - 1 - squishConst4D
        dw_ext0 = dw0MinusOneMinusSquish
        dw_ext1 = dw0MinusOneMinusSquish

      # One contribution is a permutation of (0,0,0,2) based on the
      # smaller-sided point
      xsv_ext2 = xsb
      ysv_ext2 = ysb
      zsv_ext2 = zsb
      wsv_ext2 = wsb
      dx_ext2 = dx0 - 2 * squishConst4D
      dy_ext2 = dy0 - 2 * squishConst4D
      dz_ext2 = dz0 - 2 * squishConst4D
      dw_ext2 = dw0 - 2 * squishConst4D

      if (c2 and 0x01) != 0:
        xsv_ext2 += 2
        dx_ext2 -= 2
      elif (c2 and 0x02) != 0:
        ysv_ext2 += 2
        dy_ext2 -= 2
      elif (c2 and 0x04) != 0:
        zsv_ext2 += 2
        dz_ext2 -= 2
      else:
        wsv_ext2 += 2
        dw_ext2 -= 2

    # Contribution (1,0,0,0)
    let dx1 = dx0 - 1 - squishConst4D
    let dy1 = dy0 - 0 - squishConst4D
    let dz1 = dz0 - 0 - squishConst4D
    let dw1 = dw0 - 0 - squishConst4D
    var attn1 = 2 - dx1 * dx1 - dy1 * dy1 - dz1 * dz1 - dw1 * dw1

    if attn1 > 0:
      attn1 *= attn1
      value += attn1 * attn1 *
               self.extrapolate(xsb+1, ysb+0, zsb+0, wsb+0, dx1, dy1, dz1, dw1)

    # Contribution (0,1,0,0)
    let dx2 = dx0 - 0 - squishConst4D
    let dy2 = dy0 - 1 - squishConst4D
    let dz2 = dz1
    let dw2 = dw1
    var attn2 = 2 - dx2 * dx2 - dy2 * dy2 - dz2 * dz2 - dw2 * dw2

    if attn2 > 0:
      attn2 *= attn2
      value += attn2 * attn2 *
               self.extrapolate(xsb+0, ysb+1, zsb+0, wsb+0, dx2, dy2, dz2, dw2)

    # Contribution (0,0,1,0)
    let dx3 = dx2
    let dy3 = dy1
    let dz3 = dz0 - 1 - squishConst4D
    let dw3 = dw1
    var attn3 = 2 - dx3 * dx3 - dy3 * dy3 - dz3 * dz3 - dw3 * dw3

    if attn3 > 0:
      attn3 *= attn3
      value += attn3 * attn3 *
               self.extrapolate(xsb+0, ysb+0, zsb+1, wsb+0, dx3, dy3, dz3, dw3)

    # Contribution (0,0,0,1)
    let dx4 = dx2
    let dy4 = dy1
    let dz4 = dz1
    let dw4 = dw0 - 1 - squishConst4D
    var attn4 = 2 - dx4 * dx4 - dy4 * dy4 - dz4 * dz4 - dw4 * dw4

    if attn4 > 0:
      attn4 *= attn4
      value += attn4 * attn4 *
               self.extrapolate(xsb+0, ysb+0, zsb+0, wsb+1, dx4, dy4, dz4, dw4)

    # Contribution (1,1,0,0)
    let dx5 = dx0 - 1 - 2 * squishConst4D
    let dy5 = dy0 - 1 - 2 * squishConst4D
    let dz5 = dz0 - 0 - 2 * squishConst4D
    let dw5 = dw0 - 0 - 2 * squishConst4D
    var attn5 = 2 - dx5 * dx5 - dy5 * dy5 - dz5 * dz5 - dw5 * dw5

    if attn5 > 0:
      attn5 *= attn5
      value += attn5 * attn5 *
               self.extrapolate(xsb+1, ysb+1, zsb+0, wsb+0, dx5, dy5, dz5, dw5)

    # Contribution (1,0,1,0)
    let dx6 = dx0 - 1 - 2 * squishConst4D
    let dy6 = dy0 - 0 - 2 * squishConst4D
    let dz6 = dz0 - 1 - 2 * squishConst4D
    let dw6 = dw0 - 0 - 2 * squishConst4D
    var attn6 = 2 - dx6 * dx6 - dy6 * dy6 - dz6 * dz6 - dw6 * dw6

    if attn6 > 0:
      attn6 *= attn6
      value += attn6 * attn6 *
               self.extrapolate(xsb+1, ysb+0, zsb+1, wsb+0, dx6, dy6, dz6, dw6)

    # Contribution (1,0,0,1)
    let dx7 = dx0 - 1 - 2 * squishConst4D
    let dy7 = dy0 - 0 - 2 * squishConst4D
    let dz7 = dz0 - 0 - 2 * squishConst4D
    let dw7 = dw0 - 1 - 2 * squishConst4D
    var attn7 = 2 - dx7 * dx7 - dy7 * dy7 - dz7 * dz7 - dw7 * dw7

    if attn7 > 0:
      attn7 *= attn7
      value += attn7 * attn7 *
               self.extrapolate(xsb+1, ysb+0, zsb+0, wsb+1, dx7, dy7, dz7, dw7)

    # Contribution (0,1,1,0)
    let dx8 = dx0 - 0 - 2 * squishConst4D
    let dy8 = dy0 - 1 - 2 * squishConst4D
    let dz8 = dz0 - 1 - 2 * squishConst4D
    let dw8 = dw0 - 0 - 2 * squishConst4D
    var attn8 = 2 - dx8 * dx8 - dy8 * dy8 - dz8 * dz8 - dw8 * dw8

    if attn8 > 0:
      attn8 *= attn8
      value += attn8 * attn8 *
               self.extrapolate(xsb+0, ysb+1, zsb+1, wsb+0, dx8, dy8, dz8, dw8)

    # Contribution (0,1,0,1)
    let dx9 = dx0 - 0 - 2 * squishConst4D
    let dy9 = dy0 - 1 - 2 * squishConst4D
    let dz9 = dz0 - 0 - 2 * squishConst4D
    let dw9 = dw0 - 1 - 2 * squishConst4D
    var attn9 = 2 - dx9 * dx9 - dy9 * dy9 - dz9 * dz9 - dw9 * dw9

    if attn9 > 0:
      attn9 *= attn9
      value += attn9 * attn9 *
               self.extrapolate(xsb+0, ysb+1, zsb+0, wsb+1, dx9, dy9, dz9, dw9)

    # Contribution (0,0,1,1)
    let dx10 = dx0 - 0 - 2 * squishConst4D
    let dy10 = dy0 - 0 - 2 * squishConst4D
    let dz10 = dz0 - 1 - 2 * squishConst4D
    let dw10 = dw0 - 1 - 2 * squishConst4D
    var attn10 = 2 - dx10 * dx10 - dy10 * dy10 - dz10 * dz10 - dw10 * dw10

    if attn10 > 0:
      attn10 *= attn10
      value += attn10 * attn10 *
               self.extrapolate(xsb+0, ysb+0, zsb+1, wsb+1,
                                dx10, dy10, dz10, dw10)

  else: # We're inside the second dispentachoron (Rectified 4-Simplex)

    var aScore, bScore: T
    var aPoint, bPoint: uint8
    var aIsBiggerSide = true
    var bIsBiggerSide = true

    # Decide between (0,0,1,1) and (1,1,0,0)
    if xins + yins < zins + wins:
      aScore = xins + yins
      aPoint = 0x0C
    else:
      aScore = zins + wins
      aPoint = 0x03

    # Decide between (0,1,0,1) and (1,0,1,0)
    if xins + zins < yins + wins:
      bScore = xins + zins
      bPoint = 0x0A
    else:
      bScore = yins + wins
      bPoint = 0x05

    # Closer between (0,1,1,0) and (1,0,0,1) will replace the further
    # of a and b, if closer
    if xins + wins < yins + zins:
      let score = xins + wins
      if aScore <= bScore and score < bScore:
        bScore = score
        bPoint = 0x06
      elif aScore > bScore and score < aScore:
        aScore = score
        aPoint = 0x06
    else:
      let score = yins + zins
      if aScore <= bScore and score < bScore:
        bScore = score
        bPoint = 0x09
      elif aScore > bScore and score < aScore:
        aScore = score
        aPoint = 0x09

    # Decide if (0,1,1,1) is closer
    let p1 = 3 - inSum + xins

    if aScore <= bScore and p1 < bScore:
      bScore = p1
      bPoint = 0x0E
      bIsBiggerSide = false
    elif aScore > bScore and p1 < aScore:
      aScore = p1
      aPoint = 0x0E
      aIsBiggerSide = false

    # Decide if (1,0,1,1) is closer
    let p2 = 3 - inSum + yins

    if aScore <= bScore and p2 < bScore:
      bScore = p2
      bPoint = 0x0D
      bIsBiggerSide = false
    elif aScore > bScore and p2 < aScore:
      aScore = p2
      aPoint = 0x0D
      aIsBiggerSide = false

    # Decide if (1,1,0,1) is closer
    let p3 = 3 - inSum + zins

    if aScore <= bScore and p3 < bScore:
      bScore = p3
      bPoint = 0x0B
      bIsBiggerSide = false
    elif aScore > bScore and p3 < aScore:
      aScore = p3
      aPoint = 0x0B
      aIsBiggerSide = false

    # Decide if (1,1,1,0) is closer
    let p4 = 3 - inSum + wins

    if aScore <= bScore and p4 < bScore:
      bScore = p4
      bPoint = 0x07
      bIsBiggerSide = false
    elif aScore > bScore and p4 < aScore:
      aScore = p4
      aPoint = 0x07
      aIsBiggerSide = false

    # Where each of the two closest points are determines how the
    # extra three vertices are calculated
    if aIsBiggerSide == bIsBiggerSide:
      if aIsBiggerSide: # Both closest points on the bigger side
        let c1 = aPoint and bPoint
        let c2 = aPoint or bPoint

        # Two contributions are permutations of (0,0,0,1) and
        # (0,0,0,2) based on c1
        xsv_ext0 = xsb
        xsv_ext1 = xsb
        ysv_ext0 = ysb
        ysv_ext1 = ysb
        zsv_ext0 = zsb
        zsv_ext1 = zsb
        wsv_ext0 = wsb
        wsv_ext1 = wsb
        dx_ext0 = dx0 - squishConst4D
        dy_ext0 = dy0 - squishConst4D
        dz_ext0 = dz0 - squishConst4D
        dw_ext0 = dw0 - squishConst4D
        dx_ext1 = dx0 - 2 * squishConst4D
        dy_ext1 = dy0 - 2 * squishConst4D
        dz_ext1 = dz0 - 2 * squishConst4D
        dw_ext1 = dw0 - 2 * squishConst4D

        if (c1 and 0x01) != 0:
          xsv_ext0 += 1
          dx_ext0 -= 1
          xsv_ext1 += 2
          dx_ext1 -= 2
        elif (c1 and 0x02) != 0:
          ysv_ext0 += 1
          dy_ext0 -= 1
          ysv_ext1 += 2
          dy_ext1 -= 2
        elif (c1 and 0x04) != 0:
          zsv_ext0 += 1
          dz_ext0 -= 1
          zsv_ext1 += 2
          dz_ext1 -= 2
        else:
          wsv_ext0 += 1
          dw_ext0 -= 1
          wsv_ext1 += 2
          dw_ext1 -= 2

        # One contribution is a permutation of (1,1,1,-1) based on c2
        xsv_ext2 = xsb + 1
        ysv_ext2 = ysb + 1
        zsv_ext2 = zsb + 1
        wsv_ext2 = wsb + 1
        dx_ext2 = dx0 - 1 - 2 * squishConst4D
        dy_ext2 = dy0 - 1 - 2 * squishConst4D
        dz_ext2 = dz0 - 1 - 2 * squishConst4D
        dw_ext2 = dw0 - 1 - 2 * squishConst4D

        if (c2 and 0x01) == 0:
          xsv_ext2 -= 2
          dx_ext2 += 2
        elif (c2 and 0x02) == 0:
          ysv_ext2 -= 2
          dy_ext2 += 2
        elif (c2 and 0x04) == 0:
          zsv_ext2 -= 2
          dz_ext2 += 2
        else:
          wsv_ext2 -= 2
          dw_ext2 += 2
      else: # Both closest points on the smaller side

        # One of the two extra points is (1,1,1,1)
        xsv_ext2 = xsb + 1
        ysv_ext2 = ysb + 1
        zsv_ext2 = zsb + 1
        wsv_ext2 = wsb + 1
        dx_ext2 = dx0 - 1 - 4 * squishConst4D
        dy_ext2 = dy0 - 1 - 4 * squishConst4D
        dz_ext2 = dz0 - 1 - 4 * squishConst4D
        dw_ext2 = dw0 - 1 - 4 * squishConst4D

        # Other two points are based on the shared axes
        let c = aPoint and bPoint

        if (c and 0x01) != 0:
          xsv_ext0 = xsb + 2
          xsv_ext1 = xsb + 1
          dx_ext0 = dx0 - 2 - 3 * squishConst4D
          dx_ext1 = dx0 - 1 - 3 * squishConst4D
        else:
          xsv_ext0 = xsb
          xsv_ext1 = xsb
          let dx0MinusThreeSquish = dx0 - 3 * squishConst4D
          dx_ext0 = dx0MinusThreeSquish
          dx_ext1 = dx0MinusThreeSquish

        if (c and 0x02) != 0:
          let ysbPlusOne = ysb + 1
          ysv_ext0 = ysbPlusOne
          ysv_ext1 = ysbPlusOne
          let dy0MinusOneMinusThreeSquish = dy0 - 1 - 3 * squishConst4D
          dy_ext0 = dy0MinusOneMinusThreeSquish
          dy_ext1 = dy0MinusOneMinusThreeSquish

          if (c and 0x01) == 0:
            ysv_ext0 += 1
            dy_ext0 -= 1
          else:
            ysv_ext1 += 1
            dy_ext1 -= 1

        else:
          ysv_ext0 = ysb
          ysv_ext1 = ysb
          let dy0MinusThreeSquish = dy0 - 3 * squishConst4D
          dy_ext0 = dy0MinusThreeSquish
          dy_ext1 = dy0MinusThreeSquish

        if (c and 0x04) != 0:
          let zsbPlusOne = zsb + 1
          zsv_ext0 = zsbPlusOne
          zsv_ext1 = zsbPlusOne
          let dz0MinusOneMinusThreeSquish = dz0 - 1 - 3 * squishConst4D
          dz_ext0 = dz0MinusOneMinusThreeSquish
          dz_ext1 = dz0MinusOneMinusThreeSquish

          if (c and 0x03) == 0:
            zsv_ext0 += 1
            dz_ext0 -= 1
          else:
            zsv_ext1 += 1
            dz_ext1 -= 1
        else:
          zsv_ext0 = zsb
          zsv_ext1 = zsb
          let dz0MinusThreeSquish = dz0 - 3 * squishConst4D
          dz_ext0 = dz0MinusThreeSquish
          dz_ext1 = dz0MinusThreeSquish

        if (c and 0x08) != 0:
          wsv_ext0 = wsb + 1
          wsv_ext1 = wsb + 2
          dw_ext0 = dw0 - 1 - 3 * squishConst4D
          dw_ext1 = dw0 - 2 - 3 * squishConst4D
        else:
          wsv_ext0 = wsb
          wsv_ext1 = wsb
          let dw0MinusThreeSquish = dw0 - 3 * squishConst4D
          dw_ext0 = dw0MinusThreeSquish
          dw_ext1 = dw0MinusThreeSquish

    else: # One point on each "side"
      var c1, c2: uint8
      if aIsBiggerSide:
        c1 = aPoint
        c2 = bPoint
      else:
        c1 = bPoint
        c2 = aPoint

      # Two contributions are the bigger-sided point with each 1
      # replaced with 2
      if (c1 and 0x01) != 0:
        xsv_ext0 = xsb + 2
        xsv_ext1 = xsb + 1
        dx_ext0 = dx0 - 2 - 3 * squishConst4D
        dx_ext1 = dx0 - 1 - 3 * squishConst4D
      else:
        xsv_ext0 = xsb
        xsv_ext1 = xsb
        let dx0MinusThreeSquish = dx0 - 3 * squishConst4D
        dx_ext0 = dx0MinusThreeSquish
        dx_ext1 = dx0MinusThreeSquish

      if (c1 and 0x02) != 0:
        let ysbPlusOne = ysb + 1
        ysv_ext0 = ysbPlusOne
        ysv_ext1 = ysbPlusOne
        let dy0MinusOneMinusThreeSquish = dy0 - 1 - 3 * squishConst4D
        dy_ext0 = dy0MinusOneMinusThreeSquish
        dy_ext1 = dy0MinusOneMinusThreeSquish

        if (c1 and 0x01) == 0:
          ysv_ext0 += 1
          dy_ext0 -= 1
        else:
          ysv_ext1 += 1
          dy_ext1 -= 1
      else:
        ysv_ext0 = ysb
        ysv_ext1 = ysb
        let dy0MinusThreeSquish = dy0 - 3 * squishConst4D
        dy_ext0 = dy0MinusThreeSquish
        dy_ext1 = dy0MinusThreeSquish

      if (c1 and 0x04) != 0:
        let zsbPlusOne = zsb + 1
        zsv_ext0 = zsbPlusOne
        zsv_ext1 = zsbPlusOne
        let dz0MinusOneMinusThreeSquish = dz0 - 1 - 3 * squishConst4D
        dz_ext0 = dz0MinusOneMinusThreeSquish
        dz_ext1 = dz0MinusOneMinusThreeSquish

        if (c1 and 0x03) == 0:
          zsv_ext0 += 1
          dz_ext0 -= 1
        else:
          zsv_ext1 += 1
          dz_ext1 -= 1
      else:
        zsv_ext0 = zsb
        zsv_ext1 = zsb
        let dz0MinusThreeSquish = dz0 - 3 * squishConst4D
        dz_ext0 = dz0MinusThreeSquish
        dz_ext1 = dz0MinusThreeSquish

      if (c1 and 0x08) != 0:
        wsv_ext0 = wsb + 1
        wsv_ext1 = wsb + 2
        dw_ext0 = dw0 - 1 - 3 * squishConst4D
        dw_ext1 = dw0 - 2 - 3 * squishConst4D
      else:
        wsv_ext0 = wsb
        wsv_ext1 = wsb
        let dw0MinusThreeSquish = dw0 - 3 * squishConst4D
        dw_ext0 = dw0MinusThreeSquish
        dw_ext1 = dw0MinusThreeSquish

      # One contribution is a permutation of (1,1,1,-1) based on the
      # smaller-sided point
      xsv_ext2 = xsb + 1
      ysv_ext2 = ysb + 1
      zsv_ext2 = zsb + 1
      wsv_ext2 = wsb + 1
      dx_ext2 = dx0 - 1 - 2 * squishConst4D
      dy_ext2 = dy0 - 1 - 2 * squishConst4D
      dz_ext2 = dz0 - 1 - 2 * squishConst4D
      dw_ext2 = dw0 - 1 - 2 * squishConst4D

      if (c2 and 0x01) == 0:
        xsv_ext2 -= 2
        dx_ext2 += 2
      elif (c2 and 0x02) == 0:
        ysv_ext2 -= 2
        dy_ext2 += 2
      elif (c2 and 0x04) == 0:
        zsv_ext2 -= 2
        dz_ext2 += 2
      else:
        wsv_ext2 -= 2
        dw_ext2 += 2

    # Contribution (1,1,1,0)
    let dx4 = dx0 - 1 - 3 * squishConst4D
    let dy4 = dy0 - 1 - 3 * squishConst4D
    let dz4 = dz0 - 1 - 3 * squishConst4D
    let dw4 = dw0 - 3 * squishConst4D
    var attn4 = 2 - dx4 * dx4 - dy4 * dy4 - dz4 * dz4 - dw4 * dw4

    if attn4 > 0:
      attn4 *= attn4
      value += attn4 * attn4 *
               self.extrapolate(xsb+1, ysb+1, zsb+1, wsb+0, dx4, dy4, dz4, dw4)

    # Contribution (1,1,0,1)
    let dx3 = dx4
    let dy3 = dy4
    let dz3 = dz0 - 3 * squishConst4D
    let dw3 = dw0 - 1 - 3 * squishConst4D
    var attn3 = 2 - dx3 * dx3 - dy3 * dy3 - dz3 * dz3 - dw3 * dw3

    if attn3 > 0:
      attn3 *= attn3
      value += attn3 * attn3 *
               self.extrapolate(xsb+1, ysb+1, zsb+0, wsb+1, dx3, dy3, dz3, dw3)

    # Contribution (1,0,1,1)
    let dx2 = dx4
    let dy2 = dy0 - 3 * squishConst4D
    let dz2 = dz4
    let dw2 = dw3
    var attn2 = 2 - dx2 * dx2 - dy2 * dy2 - dz2 * dz2 - dw2 * dw2

    if attn2 > 0:
      attn2 *= attn2
      value += attn2 * attn2 *
               self.extrapolate(xsb+1, ysb+0, zsb+1, wsb+1, dx2, dy2, dz2, dw2)

    # Contribution (0,1,1,1)
    let dx1 = dx0 - 3 * squishConst4D
    let dz1 = dz4
    let dy1 = dy4
    let dw1 = dw3
    var attn1 = 2 - dx1 * dx1 - dy1 * dy1 - dz1 * dz1 - dw1 * dw1

    if attn1 > 0:
      attn1 *= attn1
      value += attn1 * attn1 *
               self.extrapolate(xsb+0, ysb+1, zsb+1, wsb+1, dx1, dy1, dz1, dw1)

    # Contribution (1,1,0,0)
    let dx5 = dx0 - 1 - 2 * squishConst4D
    let dy5 = dy0 - 1 - 2 * squishConst4D
    let dz5 = dz0 - 0 - 2 * squishConst4D
    let dw5 = dw0 - 0 - 2 * squishConst4D
    var attn5 = 2 - dx5 * dx5 - dy5 * dy5 - dz5 * dz5 - dw5 * dw5

    if attn5 > 0:
      attn5 *= attn5
      value += attn5 * attn5 *
               self.extrapolate(xsb+1, ysb+1, zsb+0, wsb+0, dx5, dy5, dz5, dw5)

    # Contribution (1,0,1,0)
    let dx6 = dx0 - 1 - 2 * squishConst4D
    let dy6 = dy0 - 0 - 2 * squishConst4D
    let dz6 = dz0 - 1 - 2 * squishConst4D
    let dw6 = dw0 - 0 - 2 * squishConst4D
    var attn6 = 2 - dx6 * dx6 - dy6 * dy6 - dz6 * dz6 - dw6 * dw6

    if attn6 > 0:
      attn6 *= attn6
      value += attn6 * attn6 *
               self.extrapolate(xsb+1, ysb+0, zsb+1, wsb+0, dx6, dy6, dz6, dw6)

    # Contribution (1,0,0,1)
    let dx7 = dx0 - 1 - 2 * squishConst4D
    let dy7 = dy0 - 0 - 2 * squishConst4D
    let dz7 = dz0 - 0 - 2 * squishConst4D
    let dw7 = dw0 - 1 - 2 * squishConst4D
    var attn7 = 2 - dx7 * dx7 - dy7 * dy7 - dz7 * dz7 - dw7 * dw7

    if attn7 > 0:
      attn7 *= attn7
      value += attn7 * attn7 *
               self.extrapolate(xsb+1, ysb+0, zsb+0, wsb+1, dx7, dy7, dz7, dw7)

    # Contribution (0,1,1,0)
    let dx8 = dx0 - 0 - 2 * squishConst4D
    let dy8 = dy0 - 1 - 2 * squishConst4D
    let dz8 = dz0 - 1 - 2 * squishConst4D
    let dw8 = dw0 - 0 - 2 * squishConst4D
    var attn8 = 2 - dx8 * dx8 - dy8 * dy8 - dz8 * dz8 - dw8 * dw8

    if attn8 > 0:
      attn8 *= attn8
      value += attn8 * attn8 *
               self.extrapolate(xsb+0, ysb+1, zsb+1, wsb+0, dx8, dy8, dz8, dw8)

    # Contribution (0,1,0,1)
    let dx9 = dx0 - 0 - 2 * squishConst4D
    let dy9 = dy0 - 1 - 2 * squishConst4D
    let dz9 = dz0 - 0 - 2 * squishConst4D
    let dw9 = dw0 - 1 - 2 * squishConst4D
    var attn9 = 2 - dx9 * dx9 - dy9 * dy9 - dz9 * dz9 - dw9 * dw9

    if attn9 > 0:
      attn9 *= attn9
      value += attn9 * attn9 *
               self.extrapolate(xsb+0, ysb+1, zsb+0, wsb+1, dx9, dy9, dz9, dw9)

    # Contribution (0,0,1,1)
    let dx10 = dx0 - 0 - 2 * squishConst4D
    let dy10 = dy0 - 0 - 2 * squishConst4D
    let dz10 = dz0 - 1 - 2 * squishConst4D
    let dw10 = dw0 - 1 - 2 * squishConst4D
    var attn10 = 2 - dx10 * dx10 - dy10 * dy10 - dz10 * dz10 - dw10 * dw10

    if attn10 > 0:
      attn10 *= attn10
      value += attn10 * attn10 *
               self.extrapolate(xsb+0, ysb+0, zsb+1, wsb+1,
                                dx10, dy10, dz10, dw10)

  # First extra vertex
  var attn_ext0 = 2 - dx_ext0 * dx_ext0 - dy_ext0 * dy_ext0 -
                  dz_ext0 * dz_ext0 - dw_ext0 * dw_ext0

  if attn_ext0 > 0:
    attn_ext0 *= attn_ext0
    value += attn_ext0 * attn_ext0 *
             self.extrapolate(xsv_ext0, ysv_ext0, zsv_ext0, wsv_ext0,
                              dx_ext0, dy_ext0, dz_ext0, dw_ext0)

  # Second extra vertex
  var attn_ext1 = 2 - dx_ext1 * dx_ext1 - dy_ext1 * dy_ext1 -
                  dz_ext1 * dz_ext1 - dw_ext1 * dw_ext1

  if attn_ext1 > 0:
    attn_ext1 *= attn_ext1
    value += attn_ext1 * attn_ext1 *
             self.extrapolate(xsv_ext1, ysv_ext1, zsv_ext1, wsv_ext1,
                              dx_ext1, dy_ext1, dz_ext1, dw_ext1)

  # Third extra vertex
  var attn_ext2 = 2 - dx_ext2 * dx_ext2 - dy_ext2 * dy_ext2 -
                  dz_ext2 * dz_ext2 - dw_ext2 * dw_ext2

  if attn_ext2 > 0:
    attn_ext2 *= attn_ext2
    value += attn_ext2 * attn_ext2 *
             self.extrapolate(xsv_ext2, ysv_ext2, zsv_ext2, wsv_ext2,
                              dx_ext2, dy_ext2, dz_ext2, dw_ext2)

  result = value / normConst4D



#
# Unit tests
#

import chapunim.util.test

# Just in case, ensure that the constants have the same value as the
# ones in Kurt's Java reference implementation (which are either
# hardcoded or in a different form as I used here)
unittest:
  const epsilon = 1e-10

  assertClose(stretchConst2D, -0.211324865405187, epsilon)
  assertClose(stretchConst3D, -1/6, epsilon)
  assertClose(stretchConst4D, -0.138196601125011, epsilon)

  assertClose(squishConst2D, 0.366025403784439, epsilon)
  assertClose(squishConst3D, 1/3, epsilon)
  assertClose(squishConst4D, 0.309016994374947, epsilon)


# Construct with a default seed, check if some values in `perm` match
# those of the reference Java implemenation
unittest:
  let noise = initOpenSimplexNoise()
  doAssert(noise.perm[0] == 254)
  doAssert(noise.perm[12] == 152)
  doAssert(noise.perm[48] == 38)
  doAssert(noise.perm[77] == 150)
  doAssert(noise.perm[152] == 218)
  doAssert(noise.perm[199] == 217)
  doAssert(noise.perm[222] == 172)
  doAssert(noise.perm[255] == 211)


# Construct with a non default seed, check if some values in `perm`
# match those of the reference Java implemenation
unittest:
  let noise = initOpenSimplexNoise(171)
  doAssert(noise.perm[0] == 222)
  doAssert(noise.perm[12] == 65)
  doAssert(noise.perm[48] == 52)
  doAssert(noise.perm[77] == 225)
  doAssert(noise.perm[152] == 15)
  doAssert(noise.perm[199] == 38)
  doAssert(noise.perm[222] == 1)
  doAssert(noise.perm[255] == 46)


# Construct with the default seed, check if some values in
# `permGradIndex3D` match those of the reference Java implemenation
unittest:
  let noise = initOpenSimplexNoise()
  doAssert(noise.permGradIndex3D[0] == 42)
  doAssert(noise.permGradIndex3D[12] == 24)
  doAssert(noise.permGradIndex3D[48] == 42)
  doAssert(noise.permGradIndex3D[77] == 18)
  doAssert(noise.permGradIndex3D[152] == 6)
  doAssert(noise.permGradIndex3D[199] == 3)
  doAssert(noise.permGradIndex3D[222] == 12)
  doAssert(noise.permGradIndex3D[255] == 57)


# Construct with a non default seed, check if some values in `permGradIndex3D`
# match those of the reference Java implemenation
unittest:
  let noise = initOpenSimplexNoise(171)
  doAssert(noise.permGradIndex3D[0] == 18)
  doAssert(noise.permGradIndex3D[12] == 51)
  doAssert(noise.permGradIndex3D[48] == 12)
  doAssert(noise.permGradIndex3D[77] == 27)
  doAssert(noise.permGradIndex3D[152] == 45)
  doAssert(noise.permGradIndex3D[199] == 42)
  doAssert(noise.permGradIndex3D[222] == 3)
  doAssert(noise.permGradIndex3D[255] == 66)


# Construct with a default seed, generate noise at certain
# coordinates; compare with the values in the reference Java
# implementation
unittest:
  const epsilon = 1e-10
  let noise = initOpenSimplexNoise()

  assertClose(noise.eval(  0.1,   -0.5),  0.16815495823682902, epsilon)
  assertClose(noise.eval(  0.3,   -0.5), -0.11281949225360029, epsilon)
  assertClose(noise.eval(-10.5,    0.0), -0.37687315318724424, epsilon)
  assertClose(noise.eval(108.2,  -77.7),  0.21990349345573232, epsilon)

  assertClose(noise.eval( 0.1,  0.2, -0.3),  0.09836613421359222, epsilon)
  assertClose(noise.eval(11.1, -0.2, -4.4), -0.25745726578628725, epsilon)
  assertClose(noise.eval(-0.7,  0.9,  1.0), -0.14212747572815548, epsilon)
  assertClose(noise.eval( 0.3,  0.7,  0.2),  0.60269370138511320, epsilon)

  assertClose(noise.eval( 0.5,  0.6,  0.7,  0.8), 0.032961823285107585, epsilon)
  assertClose(noise.eval(70.2, -0.2, 10.7,  0.4), 0.038545368047082425, epsilon)
  assertClose(noise.eval(-9.9,  1.3,  0.0, -0.7), 0.309010265232531170, epsilon)
  assertClose(noise.eval( 0.0,  0.0, 99.9,  0.9), 0.102975407300067490, epsilon)


# Construct with a non default seed, generate noise at certain
# coordinates; compare with the values in the reference Java
# implementation
unittest:
  const epsilon = 1e-10
  let noise = initOpenSimplexNoise(88)

  assertClose(noise.eval(  5.1,   5.1), -0.09484174826559418, epsilon)
  assertClose(noise.eval(  1.1,  -3.1), -0.07713472832667981, epsilon)
  assertClose(noise.eval(111.2, -13.5), -0.59882723790502210, epsilon)
  assertClose(noise.eval(  0.0,  -0.1),  0.16709963561090702, epsilon)

  assertClose(noise.eval( 0.0, -0.3,  0.0), -0.37499018382847904, epsilon)
  assertClose(noise.eval( 1.3,  8.9,  0.0),  0.38463514563106793, epsilon)
  assertClose(noise.eval(-2.2, -1.1, 10.9), -0.31665633373446817, epsilon)
  assertClose(noise.eval( 0.5,  0.6,  0.7),  0.42277598705501640, epsilon)

  assertClose(noise.eval(-0.6,  0.6, -0.6,  0.6),  0.18250580763268456, epsilon)
  assertClose(noise.eval(10.0, 20.0, 30.0, 40.0), -0.29147410304623306, epsilon)
  assertClose(noise.eval( 0.5,  0.0,  0.0,  0.0),  0.08398241210986652, epsilon)
  assertClose(noise.eval(-0.8,  7.7, -7.7, 33.3), -0.20662241504474765, epsilon)


# Now, let's test the results thoroughly, comparing lots of generated
# values with values from the reference Java implementation.
#
# Too bad I don't have a tool for coverage analysis of Nim code, but
# my manual estimation suggests that this gives almost 100% of
# coverage!
when defined(unittest):
  include test_osn_expected2d
  include test_osn_expected3d
  include test_osn_expected4d

unittest:
  const epsilon = 1e-10
  const almostZero = 1e-20
  var i: int;

  # 2D
  var noise = initOpenSimplexNoise(778899)
  i = 0

  for x in countup (-6, 6):
    for y in countup (-6, 6):
      let n = noise.eval(x.float/2.2, y.float/2.2)

      if abs(expected2d[i]) < almostZero:
        assertSmall(n, epsilon)
      else:
        assertClose(n, expected2d[i], epsilon)

      inc(i)

  # 3D
  noise = initOpenSimplexNoise(102938)
  i = 0

  for x in countup (-6, 6):
    for y in countup (-6, 6):
      for z in countup (-6, 6):
        let n = noise.eval(x.float/2.2, y.float/2.2, z.float/2.2)

        if abs(expected3d[i]) < almostZero:
          assertSmall(n, epsilon)
        else:
          assertClose(n, expected3d[i], epsilon)

        inc(i)

  # 4D
  noise = initOpenSimplexNoise(657483)
  i = 0

  for x in countup (-6, 6):
    for y in countup (-6, 6):
      for z in countup (-6, 6):
        for w in countup (-6, 6):
          let n = noise.eval(x.float/2.2, y.float/2.2, z.float/2.2, w.float/2.2)

          if abs(expected4d[i]) < almostZero:
            assertSmall(n, epsilon)
          else:
            assertClose(n, expected4d[i], epsilon)

          inc(i)
