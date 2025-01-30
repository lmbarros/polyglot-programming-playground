##
## George Marsaglia's `KISS4691
## <http://mathforum.org/kb/message.jspa?messageID=7135312>`_ pseudo
## random number generator.
##
## This one should be a good first choice of algorithm for most
## applications (at least those which don't depend critically on
## random numbers, and will not get people killed or broken if
## something fails). KISS4691 passes lots of hard randomness tests, is
## simple, very fast and doesn't use much space (just under 16KB).
##
## **Author:** Leandro Motta Barros
##

import unsigned
import chapunim.rand.rng

const qSize = 4691

type
  KISS4691* = tuple ##
    ## A KISS4691 (pseudo) random number generator.
    xss: uint32 ## xor-shift state
    lcgs: uint32 ## linear congruential state
    q: array [0..qSize-1, uint32] ## multiply-with-carry state
    c: uint32 ## multiply-with-carry state
    j: uint32 ## multiply-with-carry state


proc maxValue*(self: KISS4691): uint32 =
  ## Returns the largest value this RNG can ever return.
  result = 0xFFFF_FFFF'u32


proc mwc(self: var KISS4691): uint32 {.inline.} =
  ## The multiply-with-carry component of KISS.
  self.j = if self.j < (qSize - 1): self.j + 1 else: 0

  let x = self.q[self.j]
  let t = (x shl 13) + self.c + x
  self.c = (if t < x: 1'u32 else: 0'u32) + (x shr 19)
  self.q[self.j] = t
  result = t


proc lcg(self: var KISS4691): uint32 {.inline.} =
  ## The linear congruential component of KISS.
  self.lcgs = 69069'u32 * self.lcgs + 123'u32
  result = self.lcgs


proc xs(self: var KISS4691): uint32 {.inline.} =
  ## The xor-shift component of KISS.
  self.xss = self.xss xor (self.xss shl 13)
  self.xss = self.xss xor (self.xss shr 17)
  self.xss = self.xss xor (self.xss shl 5)
  result = self.xss


proc draw*(self: var KISS4691): uint32 =
  ## Returns a (pseudo) random number between 0 and ``self.maxValue``.
  result = self.mwc() + self.lcg() + self.xs()


proc init*(self: var KISS4691, seed1, seed2: uint32) =
  ## Seeds (initializes) ``self`` with given ``seed1`` and ``seed2``
  ## values.

  self.xss = seed1
  self.lcgs = seed2
  self.c = 0
  self.j = qSize

  for i in countup(0, qSize-1):
    self.q[i] = self.lcg() + self.xs();


proc init*(self: var KISS4691, seed: uint64) =
  ## Seeds (initializes) ``self`` with given ``seed`` value.
  let seed1 = (seed and 0xFFFF_FFFF).uint32
  let seed2 = (seed shr 32).uint32
  self.init(seed1, seed2)


proc init*(self: var KISS4691, seed: SomeSignedInt) =
  ## Seeds (initializes) ``self`` with given ``seed`` value.
  self.init(seed.uint64)


proc initKISS4691*(seed1, seed2: uint32): KISS4691 =
  ## Creates a new ``KISS4691``, seeded with ``seed1`` and ``seed2``.
  result.init(seed1, seed2)


proc initKISS4691*(seed: uint64): KISS4691 =
  ## Creates a new ``KISS4691``, seeded with ``seed``.
  result.init(seed)


proc initKISS4691*(seed: SomeSignedInt): KISS4691 =
  ## Creates a new ``KISS4691``, seeded with ``seed``.
  result.init(seed)


proc initKISS4691*(): KISS4691 =
  ## Creates a new ``KISS4691``, seeded with a random seed.
  result.init(goodSeed())



#
# Unit tests
#

import chapunim.util.test
import times


# Test `draw`, comparing obtained results with those from the
# reference C implementation by George Marsaglia.
unittest:
  var rng = initKISS4691(521288629'u32, 362436069'u32)

  for i in countup(1, 1000):
    rng.draw().assertBetween(0, rng.maxValue)

  doAssert(rng.draw() == 3364474229'u32)
  doAssert(rng.draw() == 1115729069'u32)
  doAssert(rng.draw() == 3399743299'u32)
  doAssert(rng.draw() == 2505783051'u32)
  doAssert(rng.draw() == 4238293872'u32)


# Same as above, but using the single-parameter constructor.
unittest:
  var rng = initKISS4691(521288629'u32 or (362436069'u32 shl 32))

  for i in countup(1, 1000):
    rng.draw().assertBetween(0, rng.maxValue)

  doAssert(rng.draw() == 3364474229'u32)
  doAssert(rng.draw() == 1115729069'u32)
  doAssert(rng.draw() == 3399743299'u32)
  doAssert(rng.draw() == 2505783051'u32)
  doAssert(rng.draw() == 4238293872'u32)


# Like above, but using a different constructor (with a signed parameter).
unittest:
  var rng = initKISS4691(1234'i32)

  for i in countup(1, 1000):
    rng.draw().assertBetween(0, rng.maxValue)

  doAssert(rng.draw() == 434637100'u32)
  doAssert(rng.draw() == 1143909911'u32)
  doAssert(rng.draw() == 1124959757'u32)
  doAssert(rng.draw() == 2909276595'u32)
  doAssert(rng.draw() == 47744226'u32)


# Try the random seeding, just to be sure it compiles
unittest:
  var rng = initKISS4691()
  for i in countup(1, 1000):
    rng.draw().assertBetween(0, rng.maxValue)


# Call the "base" RNG procs, just to be sure they compile.
unittest:
  var rng = initKISS4691()

  rng.uniform(0.0, 1.0).assertBetween(0.0, 1.0)
  rng.uniform(1, 6).assertBetween(1, 6)
  doAssert(rng.bernoulli(1.0))
  discard rng.exponential(1.2)
  discard rng.normal(0.0, 1.3)
  discard rng.draw(WeekDay)
