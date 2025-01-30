##
## Vectors, in the linear algebra sense.
##
## **Author:** Leandro Motta Barros
##

import macros

type
  Vector*[N: static[int], T] = array[N, T] ##
    ## A vector in `N`` dimensions, with elements of type ``T``.
    ##
    ## Notice that a ``Vector`` is just an array, so all array
    ## operations are going to work with ``Vector``s and vice versa.

  Vec2f32* = Vector[2, float32] ## Handy alias for common ``Vector`` type.
  Vec2f64* = Vector[2, float64] ## Handy alias for common ``Vector`` type.
  Vec2i32* = Vector[2, int32] ## Handy alias for common ``Vector`` type.
  Vec2i62* = Vector[2, int64] ## Handy alias for common ``Vector`` type.
  Vec2u8* = Vector[2, uint8] ## Handy alias for common ``Vector`` type.

  Vec3f32* = Vector[3, float32] ## Handy alias for common ``Vector`` type.
  Vec3f64* = Vector[3, float64] ## Handy alias for common ``Vector`` type.
  Vec3i32* = Vector[3, int32] ## Handy alias for common ``Vector`` type.
  Vec3i62* = Vector[3, int64] ## Handy alias for common ``Vector`` type.
  Vec3u8* = Vector[3, uint8] ## Handy alias for common ``Vector`` type.

  Vec4f32* = Vector[4, float32] ## Handy alias for common ``Vector`` type.
  Vec4f64* = Vector[4, float64] ## Handy alias for common ``Vector`` type.
  Vec4i32* = Vector[4, int32] ## Handy alias for common ``Vector`` type.
  Vec4i62* = Vector[4, int64] ## Handy alias for common ``Vector`` type.
  Vec4u8* = Vector[4, uint8] ## Handy alias for common ``Vector`` type.


#
# Access to elements
#

template makeReadWriteElementProcs(name: expr, index: int): stmt =
  # TODO: Cannot overload by `var`. May be possible in the future,
  # see http://forum.nim-lang.org/t/914
  # proc `name`*[N: static[int], T](v: Vector[N,T]): T =
  #   assert(N > index,
  #          "Cannot use `" & astToStr(name) & "` for `Vector`s of size " & $N)
  #   result = v[index]

  # proc `name`*[N: static[int], T](v: var Vector[N,T]): var T =
  #   static: assert(N > index, "Cannot use `" & astToStr(name) &
  #                  "` for `Vector`s of size " & $N)
  #   result = v[index]

  # This works around the lack of overloading by `var`, but I couldn't
  # manage to include the `assert` there.
  template `name`*[N,T](v: Vector[N,T]): T = v[index]

  proc `name=`*[N: static[int], T](v: var Vector[N,T], val: T) =
    static: assert(N > index, "Cannot use `" & astToStr(name) &
                   "` for `Vector`s of size " & $N)
    v[index] = val


makeReadWriteElementProcs(x, 0)
makeReadWriteElementProcs(y, 1)
makeReadWriteElementProcs(z, 2)
makeReadWriteElementProcs(w, 3)

makeReadWriteElementProcs(r, 0)
makeReadWriteElementProcs(g, 1)
makeReadWriteElementProcs(b, 2)
makeReadWriteElementProcs(a, 3)

makeReadWriteElementProcs(s, 0)
makeReadWriteElementProcs(t, 1)
makeReadWriteElementProcs(p, 2)
makeReadWriteElementProcs(q, 3)


#
# Swizzling
#
macro `.`*[N, T](v: Vector[N,T], field: string): expr = ##
  ## Implements swizzling.
  ##
  ## Implemention by `def, from the Nim forum
  ## <http://forum.nim-lang.org/t/914>`_.
  result = newNimNode(nnkBracket)
  for c in field.strVal:
    result.add(newDotExpr(v, newIdentNode($c)))

macro `.=`*[N, M, T](v: Vector[N,T], field: string, rhs: Vector[M,T]): expr = ##
  ## Implements swizzling for writing.
  result = newStmtList()
  for i, c in field.strVal:
    let dotExpr = newDotExpr(v, newIdentNode($c))

    var assignment = newAssignment(dotExpr, rhs[i])
    result.add(assignment)


#
# Assorted operations
#

proc `$`*[N: static[int], T](v: Vector[N,T]): string =
  ## Converts a ``Vector`` to a ``string``.
  result = "["
  result &= $v[0]
  for i in countup(1, N-1):
    result &= ", " & $v[i]
  result &= "]"



#
# Unit tests
#

import chapunim.util.test
when defined(unittest):
  import unsigned


# Tests `$`
unittest:
  let v1 = [ 1.0, 2.0, 3.0 ]
  let vs1 = $v1
  doAssert(vs1 == "[1.0, 2.0, 3.0]")

  let v2 = [ 127'u8, 255, 0, 64 ]
  let vs2 = $v2
  doAssert(vs2 == "[127, 255, 0, 64]")

  let v3 = [ -0.2, 1.7, 0.5, 2.0 ]
  let vs3 = $v3
  doAssert(vs3 == "[-0.2, 1.7, 0.5, 2.0]")


# Tests read and write access to elements
unittest:
  # With a immutable vector
  let v0 = [ 0.0, 1.0, 2.0, 3.0 ]
  doAssert(v0.x == 0.0)
  doAssert(v0.y == 1.0)
  doAssert(v0.z == 2.0)
  doAssert(v0.w == 3.0)

  doAssert(v0.r == 0.0)
  doAssert(v0.g == 1.0)
  doAssert(v0.b == 2.0)
  doAssert(v0.a == 3.0)

  doAssert(v0.s == 0.0)
  doAssert(v0.t == 1.0)
  doAssert(v0.p == 2.0)
  doAssert(v0.q == 3.0)

  # Using indices
  var v1 = [ 0.0, 1.0, 2.0 ]
  doAssert(v1[0] == 0.0)
  doAssert(v1[1] == 1.0)
  doAssert(v1[2] == 2.0)

  v1[1] = 10.0
  doAssert(v1[0] == 0.0)
  doAssert(v1[1] == 10.0)
  doAssert(v1[2] == 2.0)

  # Using xyzw
  var v2 = [ 0'u8, 1, 2, 3 ]
  doAssert(v2.x == 0)
  doAssert(v2.y == 1)
  doAssert(v2.z == 2)
  doAssert(v2.w == 3)

  v2.x = 11
  v2.y = 22
  v2.z = 33
  v2.w = 44

  doAssert(v2.x == 11)
  doAssert(v2.y == 22)
  doAssert(v2.z == 33)
  doAssert(v2.w == 44)

  # Using rgba and stpq
  var v3 = [ 0.0'f32, 0.0, 0.0, 0.0 ]
  doAssert(v3.r == 0.0)
  doAssert(v3.g == 0.0)
  doAssert(v3.b == 0.0)
  doAssert(v3.a == 0.0)

  v3.r = -1.0
  v3.g =  2.0
  v3.b = -3.0
  v3.a =  4.0

  doAssert(v3.r == -1.0)
  doAssert(v3.g ==  2.0)
  doAssert(v3.b == -3.0)
  doAssert(v3.a ==  4.0)

  v3.s +=  1.0
  v3.t *= -10.0
  v3.p -= -1.0
  v3.q /=  2

  doAssert(v3.s ==   0.0)
  doAssert(v3.t == -20.0)
  doAssert(v3.p ==  -2.0)
  doAssert(v3.q ==   2.0)


# Tests swizzling
unittest:
  let v1 = [0.0, 1.0, 2.0, 3.0]
  doAssert(v1.wzyx == [3.0, 2.0, 1.0, 0.0])
  doAssert(v1.wwww == [3.0, 3.0, 3.0, 3.0])
  doAssert(v1.rbb == [0.0, 2.0, 2.0])
  doAssert(v1.tp == [1.0, 2.0])
  doAssert(v1.aaaaaaaa == [3.0, 3.0, 3.0, 3.0, 3.0, 3.0, 3.0, 3.0])
  doAssert(v1.aaragaba == [3.0, 3.0, 0.0, 3.0, 1.0, 3.0, 2.0, 3.0])
  doAssert(v1.ygt == [1.0, 1.0, 1.0])
  doAssert(v1.zas == [2.0, 3.0, 0.0])

  # Swizzling and assignment
  var v2 = [0.0, 1.0, 2.0, 3.0]

  doAssert(v2.x == 0.0)
  doAssert(v2.y == 1.0)
  doAssert(v2.z == 2.0)
  doAssert(v2.w == 3.0)

  v2.xy = [8.0, 9.0]

  doAssert(v2.x == 8.0)
  doAssert(v2.y == 9.0)
  doAssert(v2.z == 2.0)
  doAssert(v2.w == 3.0)

  v2.zxg = [-1.0, -2.0, -3.0]

  doAssert(v2.x == -2.0)
  doAssert(v2.y == -3.0)
  doAssert(v2.z == -1.0)
  doAssert(v2.w ==  3.0)
