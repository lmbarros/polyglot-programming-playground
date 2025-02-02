##
## A 64-bit `linear congruential
## <https://en.wikipedia.org/wiki/Linear_congruential_generator>`_
## pseudo random number generator (LCG).
##
## The multiplier and increment used here were apparently suggested by
## Don Knuth, though I have taken them from Wikipedia, not from any
## primary source.
##
## **Author:** Leandro Motta Barros
##


import unsigned
import chapunim.rand.rng


type
  KnuthLCG* = tuple ##
    ## A 64-bit linear congruential (pseudo) random number generator.
    state: uint64


proc maxValue*(self: KnuthLCG): uint64 =
  ## Returns the largest value this RNG can ever return.
  result = 0xFFFF_FFFF_FFFF_FFFF'u64


proc draw*(self: var KnuthLCG): uint64 =
  ## Returns a (pseudo) random number between 0 and ``self.maxValue``.
  self.state = 6364136223846793005'u64 * self.state + 1442695040888963407'u64
  result = self.state


proc init*(self: var KnuthLCG, seed: SomeInteger) =
  ## Seeds (initializes) ``self`` with a given ``seed`` value.
  self.state = cast[uint64](seed)


proc initKnuthLCG*(seed: SomeInteger): KnuthLCG =
  ## Creates a new ``KnuthLCG``, seeded with ``seed``.
  result.init(seed)


proc initKnuthLCG*(): KnuthLCG =
  ## Creates a new ``KnuthLCG``, seeded with a random seed.
  result.init(goodSeed())



#
# Unit tests
#

import chapunim.util.test
import times


# Test `draw`
unittest:
  var rng = initKnuthLCG(112233)

  # Call `draw` 1000 times, checking if values are in range. Well, considering it
  # is an `uint64`, it cannot be out of range, but anyway
  for i in countup(1, 1000):
    rng.draw().assertBetween(0, rng.maxValue)

  # Check the next few values, comparing them those generated by a C
  # implementation I found somewhere
  doAssert(rng.draw() == 14373087394460283212'u64)
  doAssert(rng.draw() == 17919820627726294955'u64)
  doAssert(rng.draw() == 2374928239783487326'u64)
  doAssert(rng.draw() == 1355612529541287637'u64)
  doAssert(rng.draw() == 14300717203320031168'u64)

  # Again, with a different seed
  rng.init(97531)
  for i in countup(1, 1000):
    rng.draw().assertBetween(0, rng.maxValue)
  doAssert(rng.draw() == 2475730772265627958'u64)
  doAssert(rng.draw() == 16585264879776313805'u64)
  doAssert(rng.draw() == 10829226592693777752'u64)
  doAssert(rng.draw() == 4337668493995821511'u64)
  doAssert(rng.draw() == 13619766792622649930'u64)


# Try the random seeding, just to be sure it compiles
unittest:
  var rng = initKnuthLCG()
  for i in countup(1, 1000):
    rng.draw().assertBetween(0, rng.maxValue)


# Call the "base" RNG procs, just to be sure they compile.
unittest:
  var rng = initKnuthLCG()

  rng.uniform(0.0, 1.0).assertBetween(0.0, 1.0)
  rng.uniform(1, 6).assertBetween(1, 6)
  doAssert(rng.bernoulli(1.0))
  discard rng.exponential(1.2)
  discard rng.normal(0.0, 1.3)
  discard rng.draw(WeekDay)
