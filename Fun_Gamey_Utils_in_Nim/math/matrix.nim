##
## Matrices, in the linear algebra sense.
##
## **Author:** Leandro Motta Barros
##

import chapunim.math.vector


type
  Matrix*[R, C: static[int], T] = array[R, array[C, T]] ##
    ## A matrix of `R`` rows by ``C`` columns, with elements of type
    ## ``T``. Elements are stored in memory in a row-major order.

  Mat2x2f32* = Matrix[2,2,float32] ## Handy alias for common ``Matrix`` type.
  Mat2x2f64* = Matrix[2,2,float64] ## Handy alias for common ``Matrix`` type.
  Mat2x2i32* = Matrix[2,2,int32] ## Handy alias for common ``Matrix`` type.
  Mat2x2i64* = Matrix[2,2,int64] ## Handy alias for common ``Matrix`` type.

  Mat2x3f32* = Matrix[2,3,float32] ## Handy alias for common ``Matrix`` type.
  Mat2x3f64* = Matrix[2,3,float64] ## Handy alias for common ``Matrix`` type.
  Mat2x3i32* = Matrix[2,3,int32] ## Handy alias for common ``Matrix`` type.
  Mat2x3i64* = Matrix[2,3,int64] ## Handy alias for common ``Matrix`` type.

  Mat2x4f32* = Matrix[2,4,float32] ## Handy alias for common ``Matrix`` type.
  Mat2x4f64* = Matrix[2,4,float64] ## Handy alias for common ``Matrix`` type.
  Mat2x4i32* = Matrix[2,4,int32] ## Handy alias for common ``Matrix`` type.
  Mat2x4i64* = Matrix[2,4,int64] ## Handy alias for common ``Matrix`` type.

  Mat3x2f32* = Matrix[3,2,float32] ## Handy alias for common ``Matrix`` type.
  Mat3x2f64* = Matrix[3,2,float64] ## Handy alias for common ``Matrix`` type.
  Mat3x2i32* = Matrix[3,2,int32] ## Handy alias for common ``Matrix`` type.
  Mat3x2i64* = Matrix[3,2,int64] ## Handy alias for common ``Matrix`` type.

  Mat3x3f32* = Matrix[3,3,float32] ## Handy alias for common ``Matrix`` type.
  Mat3x3f64* = Matrix[3,3,float64] ## Handy alias for common ``Matrix`` type.
  Mat3x3i32* = Matrix[3,3,int32] ## Handy alias for common ``Matrix`` type.
  Mat3x3i64* = Matrix[3,3,int64] ## Handy alias for common ``Matrix`` type.

  Mat3x4f32* = Matrix[3,4,float32] ## Handy alias for common ``Matrix`` type.
  Mat3x4f64* = Matrix[3,4,float64] ## Handy alias for common ``Matrix`` type.
  Mat3x4i32* = Matrix[3,4,int32] ## Handy alias for common ``Matrix`` type.
  Mat3x4i64* = Matrix[3,4,int64] ## Handy alias for common ``Matrix`` type.

  Mat4x2f32* = Matrix[4,2,float32] ## Handy alias for common ``Matrix`` type.
  Mat4x2f64* = Matrix[4,2,float64] ## Handy alias for common ``Matrix`` type.
  Mat4x2i32* = Matrix[4,2,int32] ## Handy alias for common ``Matrix`` type.
  Mat4x2i64* = Matrix[4,2,int64] ## Handy alias for common ``Matrix`` type.

  Mat4x3f32* = Matrix[4,3,float32] ## Handy alias for common ``Matrix`` type.
  Mat4x3f64* = Matrix[4,3,float64] ## Handy alias for common ``Matrix`` type.
  Mat4x3i32* = Matrix[4,3,int32] ## Handy alias for common ``Matrix`` type.
  Mat4x3i64* = Matrix[4,3,int64] ## Handy alias for common ``Matrix`` type.

  Mat4x4f32* = Matrix[4,4,float32] ## Handy alias for common ``Matrix`` type.
  Mat4x4f64* = Matrix[4,4,float64] ## Handy alias for common ``Matrix`` type.
  Mat4x4i32* = Matrix[4,4,int32] ## Handy alias for common ``Matrix`` type.
  Mat4x4i64* = Matrix[4,4,int64] ## Handy alias for common ``Matrix`` type.



#
# Operators
#

proc `*`*[R1,C1,R2,C2,T](lhs: Matrix[R1,C1,T], rhs: Matrix[R2,C2,T]):
  Matrix[R1,C2,T] {.noinit.} =
  ## Matrix by matrix multiplication.
  static: assert(C1 == R2, "Invalid matrix dimensions for multiplication")

  for i in countup(0, R1-1):
    for j in countup(0, C2-1):
      var sum: T = 0
      for k in countup(0, C1-1):
        sum += lhs[i][k] * rhs[k][j]

      result[i][j] = sum


proc `*`*[RC,T](lhs: Vector[RC,T], rhs: Matrix[RC,RC,T]):
  Vector[RC,T] {.noinit.} =
  ## Multiplies a vector ``lhs`` (assumed to be a row vector) by a
  ## square matrix ``rhs``.
  ##
  ## At this moment, the library doesn't provide any handy means to
  ## perform matrix-vector multiplications using column vectors.
  for i in countup(0, RC-1):
    for j in countup(0, RC-1):
      result[i] += lhs[j] * rhs[j][i]



proc `$`*[R, C, T](m: Matrix[R,C,T]): string =
  ## Converts a ``Matrix`` to a ``string``.
  result = "["
  result &= $m[0]
  for i in countup(1, R-1):
    result &= ", " & $m[i]
  result &= "]"



#
# Misellaneous operations
#

proc makeIdentity*[RC,T](m: var Matrix[RC,RC,T]) =
  ## Makes ``m`` an identity matrix.
  ##
  ## **TODO:** I need a way to constuct identity matrices without
  ##           having to provide a previously initialized ``Matrix``.
  for i in countup(0,RC-1):
    for j in countup(0,RC-1):
      m[i][j] = if i == j: 1.T else: 0.T



#
# Unit tests
#

import chapunim.util.test


# Be sure that data is really stored in a row-major order
unittest:
  let m: Mat2x3i32 = [ [0'i32, 1, 2],
                       [3'i32, 4, 5] ]

  doAssert(cast[array[6,int32]](m) == [0'i32, 1, 2, 3, 4, 5])


# Tests ``makeIdentity``
unittest:
  var i2: Mat2x2f32
  i2.makeIdentity()
  doAssert(i2 == [ [1.0'f32, 0.0],
                   [0.0'f32, 1.0] ])

  var i3: Mat3x3f64
  i3.makeIdentity()
  doAssert(i3 == [ [1.0, 0.0, 0.0],
                   [0.0, 1.0, 0.0],
                   [0.0, 0.0, 1.0] ])

  var i4: Mat4x4i32
  i4.makeIdentity()
  doAssert(i4 == [ [1'i32, 0, 0, 0],
                   [0'i32, 1, 0, 0],
                   [0'i32, 0, 1, 0],
                   [0'i32, 0, 0, 1] ])


# Tests `$` (conversion to string)
unittest:
  let m1 = [ [1.0, 2.0, 3.0],
             [4.0, 5.0, 6.0] ]
  doAssert($m1 == "[[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]]")

  var m2 = [ [1, 2, 3, 4],
             [5, 6, 7, 8] ]
  doAssert($m2 == "[[1, 2, 3, 4], [5, 6, 7, 8]]")

  let m3 = [ [1'u8,   2,  3],
             [4'u8,   5,  6],
             [7'u8,   8,  9],
             [10'u8, 11, 12] ]
  doAssert($m3 == "[[1, 2, 3], [4, 5, 6], [7, 8, 9], [10, 11, 12]]")


# Tests matrix by matrix multiplication
unittest:
  # 3x3 * 3x3
  let m1 = [ [1, -5,  3],
             [0, -2,  6],
             [7,  2, -4] ]

  let m2 = [ [-8, 6,  1],
             [ 7, 0, -3],
             [ 2, 4,  5] ]

  doAssert(m1 * m2 == [ [-37, 18,  31],
                        [ -2, 24,  36],
                        [-50, 26, -19] ])

  # 2x2 * 2x2
  var m3 = [ [-3.0, 0.0],
             [ 5.0, 0.5] ]

  var m4 = [ [-7.0, 2.0],
             [ 4.0, 6.0] ]

  doAssert(m3 * m4 == [ [ 21.0, -6.0 ],
                        [-33.0, 13.0] ])

  # 3x2 * 2x4
  let m5 = [ [6, -4],
             [7, -1],
             [5,  3] ]

  var m6 = [ [ 1, 2, -2, 4],
             [-4, 6,  7, 8] ]

  doAssert(m5 * m6 == [ [22, -12, -40, -8],
                        [11,   8, -21, 20],
                        [-7,  28,  11, 44] ])

  # 4x4 * identity
  let m7 = [ [ 8.8, -0.2, 3.3, -1.1],
             [ 0.5,  0.2, 2.6, -2.5],
             [-0.1,  1.7, 0.4,  1.3],
             [ 0.0,  0.9, 3.3, -0.8] ]

  var i4: Mat4x4f64
  i4.makeIdentity()
  assert(m7 * i4 == m7)


# Tests matrix by vector multiplication
unittest:
  const epsilon = 1e-6

  # 3 * 3x3
  let v1 = [ 2, -3, -3 ]
  let m1 = [ [-2, -6, -2],
             [ 3, -3, -4],
             [ 1, -1,  1] ]
  var i1: Matrix[3,3,int]
  i1.makeIdentity()

  doAssert(v1 * m1 == [-16, 0, 5])
  doAssert(v1 * i1 == v1)

  # 4 * 4*4
  var v2 = [ -4.3, 4.3, 3.4, 7.7 ]
  var m2 = [ [ 2.3,  4.5, -1.8,  2.0],
             [ 5.2, -4.4,  5.2, -1.2],
             [ 7.0, -7.0,  0.0,  1.0],
             [-1.0,  1.6,  1.7,  5.1] ]
  let r2 = v2 * m2
  assertClose(r2.x,  28.57, epsilon)
  assertClose(r2.y, -49.75, epsilon)
  assertClose(r2.z,  43.19, epsilon)
  assertClose(r2.w,  28.91, epsilon)

  var i2: Matrix[4,4,float]
  i2.makeIdentity()
  assert(v2 * i2 == v2);

  # 2 * 2x2
  let v3 = [ -1.0, 2.0 ]
  let m3 = [ [-1.3, 5.3],
             [ 0.1, 7.2] ]

  let r3 = v3 * m3

  assertClose(r3.x, 1.5, epsilon);
  assertClose(r3.y, 9.1, epsilon);

  var i3: Matrix[2,2,float]
  i3.makeIdentity()
  assert(v3 * i3 == v3)
