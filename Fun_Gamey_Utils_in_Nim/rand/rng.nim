##
## Base definitions for random number generators.
##
## **Author:** Leandro Motta Barros
##

import math
import times
import unsigned
import chapunim.util.test

when hostOS == "windows":
  import windows
else:
  import posix



type
  RNG* = generic r, var vr
    ## This is the interface that must be implemented by random number
    ## generators. Just two things are required:
    ##
    ## - A ``maxValue`` "property" (a proc, really) telling what is
    ##   the maximum value this RNG will ever return. (It is assumed
    ##   that the mininum is zero.)
    ##
    ## - A ``draw()`` method that returns an unsigned integer value
    ##   from a uniform distribution, which is the random number
    ##   itself (which must be between 0 and ``maxValue``).
    ##
    ## Seeding (initialization) is not included here because different
    ## algorithms may require different data for initialization, and
    ## real random number generators may not require seeding at all.
    r.maxValue is SomeUnsignedInt
    vr.draw() is SomeUnsignedInt


proc uniform*(self: var RNG, a: float = 0.0, b: float = 1.0): float =
  ## Uses ``self`` to generate a floating point number between ``a``
  ## and ``b`` (interval closed at both ends); returns this number.
  ##
  ## Default parameters generate numbers between 0.0 and 1.0. ``a``
  ## cannot be larger than ``b``.
  assert(a <= b)
  result = (self.draw().float / self.maxValue().float) * (b - a) + a


proc uniform*[T: SomeInteger](self: var RNG, a: T, b: T): T =
  ## Uses ``self`` to generate an integer number between ``a`` and
  ## ``b`` (interval closed at both ends); returns this number.
  ##
  ## ``a`` cannot be larger than ``b``.
  ##
  ## This uses a simple logic, based on the ``mod`` operator. This has
  ## at least two consequences:
  ##
  ## 1. It will only produce a reasonably uniform distribution if
  ##    ``abs(b - a)`` is much smaller than ``self.maxValue``. In
  ##    other words, this is OK to simulate rolls of dice, but will
  ##    generate skewed distributions if used to generate random
  ##    numbers in a large interval like, perhaps, 0 to 1_000_000.
  ##
  ## 2. The quality of the random number generator -- especially of
  ##    the lower-order bits -- is very important to guarantee a good
  ##    uniformity in the generated distribution.
  ##
  ## **TODO:** Implement a version that works for large intervals. See
  ##           http://stackoverflow.com/a/6852396, for example.
  assert(a <= b)
  let base = self.draw().uint64 mod (b - a + 1).uint64
  result = base.T + a


proc bernoulli*(self: var RNG, p: float = 0.5): bool =
  ## Uses ``self`` to generate a Boolean random value, which has a
  ## probability ``p`` of being ``true`` (a Bernoulli
  ## distribution).
  ##
  ## Default value for ``p`` is 0.5, which represents a fair coin
  ## toss.
  ##
  ## For ``p <= 0``, ``false`` is always returned. For ``p >= 1``,
  ## ``true`` is always returned.
  result = self.draw().float < self.maxValue.float * p


proc exponential*(self: var RNG, mean: float = 1.0): float =
  ## Uses ``self`` to generate a floating point random value from an
  ## exponential distribution with mean ``mean`` (1.0 by default).
  let r01 = self.draw().float / self.maxValue().float
  result = -mean * ln(r01)


proc normal*(self: var RNG, mean: float = 0.0, stdDev: float = 1.0): float =
  ## Uses ``self`` to generate a floating point random value from a
  ## normal (Gaussian) distribution with mean ``mean`` (0.0 by
  ## default) and standard deviation ``stdDev`` (1.0 by default).
  ##
  ## ``stdDev`` must be non negative.
  ##
  ## This implements an algorithm for computing an approximation of
  ## the inverse normal cumulative distribution function, which is
  ## pretty accurate. This algorithm which was created by Peter John
  ## Acklam, who describes it `on his web page
  ## <http://home.online.no/~pjacklam/notes/invnorm/>`_.

  assert(stdDev >= 0.0)

  # Coefficients in rational approximations
  const
    a1 = -3.969683028665376e+01
    a2 =  2.209460984245205e+02
    a3 = -2.759285104469687e+02
    a4 =  1.383577518672690e+02
    a5 = -3.066479806614716e+01
    a6 =  2.506628277459239e+00

    b1 = -5.447609879822406e+01
    b2 =  1.615858368580409e+02
    b3 = -1.556989798598866e+02
    b4 =  6.680131188771972e+01
    b5 = -1.328068155288572e+01

    c1 = -7.784894002430293e-03
    c2 = -3.223964580411365e-01
    c3 = -2.400758277161838e+00
    c4 = -2.549732539343734e+00
    c5 =  4.374664141464968e+00
    c6 =  2.938163982698783e+00

    d1 =  7.784695709041462e-03
    d2 =  3.224671290700398e-01
    d3 =  2.445134137142996e+00
    d4 =  3.754408661907416e+00

  # Define break-points
  const
    pLow  = 0.02425
    pHigh = 1 - pLow

  # Input and output variables
  var p = 0.0
  while (p <= 0.0 or p >= 1.0):
    p = self.draw().float / self.maxValue().float

  assert(p > 0.0 and p < 1.0) # `p` must be in the open interval (0, 1)

  var x: float

  # Rational approximation for lower region
  if p < pLow:
    let q = sqrt(-2 * ln(p))
    x = (((((c1 * q + c2) * q + c3) * q + c4) * q + c5) * q + c6) /
        ((((d1 * q + d2) * q + d3) * q + d4) * q + 1)

  # Rational approximation for central region
  elif p <= pHigh:
    let q = p - 0.5
    let r = q * q
    x = (((((a1 * r + a2) * r + a3) * r + a4) * r + a5) * r + a6) * q /
        (((((b1 * r + b2) * r + b3) * r + b4) * r + b5) * r + 1)

  # Rational approximation for upper region
  else:
    assert(p > pHigh)
    let q = sqrt(-2 * ln(1-p))
    x = -(((((c1 * q + c2) * q + c3) * q + c4) * q + c5) * q + c6) /
         ((((d1 * q + d2) * q + d3) * q + d4) * q + 1)

  # There we are
  result = x * stdDev + mean


proc draw*[R](self: var R, E: typedesc[enum]): E =
  ## Uses ``self`` to draw one of the possible values in enumeration
  ## ``E``. This doesn't work with enumerations with holes.
  ##
  ## **TODO:** Template parameter should be declared as ``[R:
  ##           RNG]``. Or, even better: just use ``self: var RNG`` as
  ##           a regular parameter. Too bad this freezes the compiler,
  ##           as of 2015-02-20.
  let r = self.uniform(E.low.ord, E.high.ord)
  result = E.type(r)


proc goodSeed*(): uint64 =
  ## Produces a number which is a good seed to initialize a (pseudo)
  ## random number generator.
  let time = getTime().uint64
  when hostOS == "windows":
    let pid = GetCurrentProcessId().uint64
  else:
    let pid = getpid().uint64

  result = (pid shl 32) or time


#
# Unit tests
#

# This is a minimal implementation of a compliant RNG, just for the
# sake of testing. (If you are looking for a linear congruential
# generator, look at the `lcg` module, which has a presumably better
# implementation than this one).
when defined(unittest):
  type
    TestRNG = tuple [state: uint32]

  proc maxValue(self: TestRNG): uint32 =
    result = uint32.high

  proc draw(self: var TestRNG): uint32 =
    self.state = 1103515245'u32 * self.state + 12345'u32
    result = self.state

  proc seed[T: SomeInteger](self: var TestRNG, s: T) =
    self.state = cast[uint32](s)


# Tests `uniform` for floating point values
unittest:
  var rng = (state: 0'u32)
  rng.seed(12345)

  const n = 1000

  # Helper to test non degenerate intervals. Doesn't really guarantee
  # anything -- and doesn't even try to test if the distribution is
  # uniform. But at least ensures no number will be out of the
  # requested range
  proc testInterval(a, b: float) =
    assert(a < b)

    # Try the interval passed in
    for i in countup(1, n):
      let r = rng.uniform(a, b)
      r.assertBetween(a, b)

  # Test some interesting intervals
  testInterval(  0.0,  1.0)
  testInterval(  1.0,  3.3)
  testInterval(-10.0, -2.0)
  testInterval( -2.20, 4.3)
  testInterval( -1.50, 0.0)

  # Test two degenerate (but still valid) intervals: a == b, with
  # float64 and float32
  for i in countup(1, n):
    let r = rng.uniform(5.0'f64, 5.0'f64)
    doAssert(r == 5.0'f64)

  for i in countup(1, n):
    let r = rng.uniform(-3.0'f32, -3.0'f32)
    doAssert(r == -3.0'f32)

  # Test using the default parameters, which shall be a=0 and b=1
  for i in countup(1, n):
    let r = rng.uniform()
    doAssert(r >= 0.0 and r <= 1.0)



# Tests `uniform` for integer values
unittest:
  var rng = (state: 0'u32)
  rng.seed(-9876)

  const n = 1000

  # Helper to test non degenerate intervals. Please use intervals much
  # smaller than `n`, so that the `wasGenerated` logic has a good
  # chance to work.
  template testInterval(a, b: SomeInteger) =
    assert(a < b)

    var wasGenerated: array[a..b, bool]

    for i in countup(a, b):
      wasGenerated[i] = false

    # Try the interval passed in
    for i in countup(1, n):
      let r = rng.uniform(a, b)
      r.assertBetween(a, b)
      wasGenerated[r] = true

    # Check if all numbers in the range were generated
    for i in countup(a, b):
      doAssert(wasGenerated[i])

  # Test some interesting intervals
  testInterval(1, 6)
  testInterval(0, 4)
  testInterval(-10, -2)
  testInterval(-2, 4)
  testInterval(-4, 0)

  # Try with some different integer types, too
  testInterval(4'u16, 7'u16)
  testInterval(4'i8, 12'i8)


# Tests `bernoulli`
unittest:
  var rng = (state: 0'u32)
  rng.seed(365'u16)

  const n = 5000
  const epsilon = 0.05 # for assertClose; cannot be too strict for such small n

  # Try with the default parameter, p = 0.5
  var numTrues = 0
  for i in countup(1, n):
    if rng.bernoulli(): numTrues += 1

  assertClose(numTrues / n, 0.5, epsilon)

  # Helper to test with arbitrary p
  proc testWithP(p: float, expectedP: float) =
    var numTrues = 0
    for i in countup(1, n):
      if rng.bernoulli(p): numTrues += 1

    assertClose(numTrues / n, expectedP, epsilon)

  # Test with some values of p
  testWithP(0.0, 0.0)
  testWithP(0.2, 0.2)
  testWithP(0.7, 0.7)
  testWithP(1.0, 1.0)

  testWithP(-1.1, 0.0)
  testWithP(-100.0, 0.0)
  testWithP(1.1, 1.0)
  testWithP(100.0, 1.0)


# Tests `exponential` -- er, kinda. I don't make any effort to ensure
# that the numbers are really drawn from an exponential distribution
unittest:
  var rng = (state: 0'u32)
  rng.seed(11111111)

  const n = 5000
  const epsilon = 0.05 # for such a small n, a relatively large epsilon

  # Test with the default mean value (which is 1.0)
  var vals = newSeq[float](n)
  for i in countup(0, n-1):
    vals[i] = rng.exponential()
  assertClose(mean(vals), 1.0, epsilon)

  # Helper to test `exponential` with a given mean
  proc testWithMean(mean: float) =
    for i in countup(0, n-1):
      vals[i] = rng.exponential(mean)
    assertClose(mean(vals), mean, epsilon)

  # Test some mean values
  testWithMean(1.0)
  testWithMean(2.0)
  testWithMean(33.3)
  testWithMean(-1.0)
  testWithMean(-0.1)
  testWithMean(0.0)


# Tests `normal` -- again, I don't make any effort to ensure that the
# numbers are really drawn from a normal distribution
unittest:
  var rng = (state: 0'u32)
  rng.seed(-500001)

  const n = 1000
  const epsilon = 0.05 # for such a small n, a relatively large epsilon

  # Test with the default parameters (mean = 0.0, stdDev = 1.0)
  var vals = newSeq[float](n)
  for i in countup(0, n-1):
    vals[i] = rng.normal()
  assertSmall(mean(vals), epsilon)
  assertClose(sqrt(variance(vals)), 1.0, epsilon)

  # Helper to test with given parameters
  proc testWithParams(mean, stdDev: float) =
    for i in countup(0, n-1):
      vals[i] = rng.normal(mean, stdDev)
    assertClose(mean(vals), mean, epsilon)
    assertClose(sqrt(variance(vals)), stdDev, epsilon)

  # Test with some parameters
  testWithParams(0.1, 1.0)
  testWithParams(1.0, 0.1)
  testWithParams(10.0, 3.0)
  testWithParams(-5.0, 3.0)


# Tests `draw` (from enumeration)
unittest:
  var rng = (state: 0'u32)
  rng.seed(657483)

  const n = 1000

  {.hint[XDeclaredButNotUsed]: off.}
  type
    FirstEnum = enum feA, feB, feC
    SecondEnum = enum seA = 171, seB, seC, seD, seE

  var
    firstArray: array[FirstEnum, bool] = [ false, false, false ]
    secondArray: array[SecondEnum, bool] = [ false, false, false, false, false ]

  # First enumeration
  for i in countup(1, n):
    let r = rng.draw(FirstEnum)
    firstArray[r] = true

  for i in items(FirstEnum):
    doAssert(firstArray[i])

  # Second enumeration
  for i in countup(1, n):
    let r = rng.draw(SecondEnum)
    secondArray[r] = true

  for i in items(SecondEnum):
    doAssert(secondArray[i])


# Just calls `goodSeed`. I cannot think of any way to test if what it
# produces is indeed a good seed. So, at least, ensure the call
# compiles.
unittest:
  discard goodSeed()
