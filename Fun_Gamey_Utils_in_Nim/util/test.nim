##
## Assorted test-related utilities.
##
## **Author:** Leandro Motta Barros
##

import typetraits


template unittest*(body: stmt) {.immediate.} =
  ## Creates a unit test with a given body.
  ##
  ## A poor man's unit test facility. Initially based on the `public
  ## domain implementation <http://forum.nim-lang.org/t/653>`_ sent by
  ## user PV to the Nim forums, but this has evolved a bot since
  ## then.
  ##
  ## This tries to be spiritually similar to D's very handy
  ## ``unittest`` blocks. This implementation just runs ``body`` as
  ## part of the "main program" when the code is compiled with
  ## ``-d:unittest``.
  {.push warning[user]: off.}
  when defined(unittest):
    # Put `body` in an anonymous proc so that it doesn't pollute the
    # global namespace and things like `defer` and closures work as
    # expected.
    (proc() = body)()
  {.pop.}


proc isClose*[U, V, E: SomeNumber](u: U, v: V, e: E): bool =
  ## Checks whether `u` and `v` are close to each other within a tolerance
  ## of `e`.
  ##
  ## This implements the same "very close with tolerance *e*"
  ## algorithm used by `Boost Test
  ## <http://www.boost.org/doc/libs/1_56_0/libs/test/doc/html/utf/testing-tools/floating_point_comparison.html>`_,
  ## which works nicely with both very large and very small numbers.
  let d = abs(u - v)
  result = d == 0 or (d / abs(u) <= e and d / abs(v) <= e)


proc assertClose*[U, V, E: SomeNumber](u: U, v: V, e: E): void =
  ## Checks whether `u` and `v` are close to each other within a
  ## tolerance of `e`, using `isClose`.
  ##
  ## This is intended to be used in unit tests; internally it uses
  ## `doAssert()` instead of `assert()`, so it is enabled even in
  ## release builds.
  doAssert(
    isClose(u, v, e),
    "assertClose failure: " & $u & " and " & $v & " are not within " &
      $e & " tolerance")


proc assertSmall*[V, E: SomeNumber](v: V, e: E): void =
  ## Checks whether ``v`` is "small enough"; useful for testing if a value is
  ## equals to zero, within a tolerance ``e``.
  ##
  ## The algorithm used by ``assertClose()`` is not appropriate for
  ## testing if a value is (approximately) zero. Use this test
  ## instead.
  ##
  ## This is intended to be used in unit tests; internally it uses
  ## `doAssert()` instead of `assert()`, so it is enabled even in
  ## release builds.
  let d = abs(v)
  doAssert(d <= e, "assertSmall failure: " & $v & " is not small " &
         "enough (tolerance = " & $e & ")")


proc assertBetween*[T: SomeNumber](n: T, a: T, b: T) =
  ## Checks whether `n` is between `a` and `b` (inclusive at both
  ## ends). `b` cannot be smaller than `a`.
  ##
  ## This is intended to be used in unit tests; internally it uses
  ## `doAssert()` instead of `assert()`, so it is enabled even in
  ## release builds.

  # Here, we use assert() instead of doAssert() because this is
  # testing the consistency of the input parameters
  assert(a <= b)

  # Here's what the caller wants to test -- even in release builds;
  # ergo, doAssert()
  doAssert(
    n >= a and n <= b,
    "assertBetween failure: " & $n & " is not between " & $a & " and " & $b)


template assertRaises*(E: static[expr], code: stmt) =
  ## Checks that that `E` is raised during the execution of `code`. In
  ## other words, causes an `assert` to fail if `E` is not raised.
  ##
  ## This is intended to be used in unit tests; internally it uses
  ## `doAssert()` instead of `assert()`, so it is enabled even in
  ## release builds.
  var raised = false

  try:
    code
  except E:
    raised = true
  except:
    raised = false

  doAssert(raised, "Exception " & E.name & " not raised")


template assertAsserts*(code: stmt) =
  ## Checks that an `assert` fails during the execution of `code`. In
  ## other words, causes an `assert` to fail if `AssertionError` is
  ## not raised.
  ##
  ## This is intended to be used in unit tests; internally it uses
  ## `doAssert()` instead of `assert()`, so it is enabled even in
  ## release builds.
  assertRaises(AssertionError):
    code



#
# Unit tests
#

unittest:
  assertClose(0.001, 0.001001, 0.001)
  assertClose(0.001001, 0.001, 0.001)

  assertAsserts: assertClose(0.001, 0.001001, 0.0001)

  assertAsserts: assertClose(0.001001, 0.001, 0.0001)

  assertClose(10.0e4, 10.01e4, 0.001)
  assertClose(10.01e4, 10.0e4, 0.001)

  assertAsserts: assertClose(10.0e4, 10.01e4, 0.0001)
  assertAsserts: assertClose(10.01e4, 10.0e4, 0.0001)

  assertBetween(2, 1, 3)
  2.assertBetween(1, 3)
  2.0.assertBetween(1.0, 3.0)
  2'i8.assertBetween(1'i8, 3'i8)

  (-1).assertBetween(-2, 5)
  (-3).assertBetween(-5, -2)
  5.assertBetween(5, 5)
  5.assertBetween(0, 5)
  5.assertBetween(5, 15)

  assertAsserts: 5.assertBetween(1, 2)
  assertAsserts: 1.2.assertBetween(1.201, 1.3)

  assertSmall( 0.001, 0.0011)
  assertSmall(-0.001, 0.0011)
  assertSmall( 0.1, 0.1)
  assertSmall(-0.1, 0.1)
  assertAsserts: assertSmall(0.001, 0.0009)
  assertAsserts: assertSmall(-0.001, 0.0009)
