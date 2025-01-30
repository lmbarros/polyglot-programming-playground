##
## Provides ways to combine several layers of noise in order to create
## fractal-like noise.
##
## I have seen this technique being called `fractional Brownian motion
## <https://code.google.com/p/fractalterraingeneration/wiki/Fractional_Brownian_Motion>_`,
## but I am not math literate enough to understand how this would
## relate to the `general concept
## <https://en.wikipedia.org/wiki/Fractional_Brownian_motion>`_ of
## fractional Brownian motion.
##
## **Author:** Leandro Motta Barros.
##
## **TODO:** Make this work with ``float32``.
##


type
  noiseProc2D* = proc(x, y: float): float ## 2D noise function.
  noiseProc3D* = proc(x, y, z: float): float ## 3D noise function.
  noiseProc4D* = proc(x, y, z, w: float): float ## 4D noise function.


proc makeFractalNoiseProc*(noiseProc: noiseProc2D,
                           octaves: int,
                           lacunarity: float = 2.0,
                           gain: float = 0.5): noiseProc2D =
  ##  Creates and returns a ``proc`` that will generate 2D fractal
  ##  noise.
  ##
  ##  The returned ``proc``, when called, will sample ``noiseProc``
  ##  ``octave`` times and combine the results to generate the final
  ##  noise value. In each call, the sampling frequency is multiplied
  ##  by ``lacunarity`` and the amplitude is multiplied by ``gain``.
  assert(octaves > 0, "Need a positive number of octaves, got " & $octaves)

  result = proc(x, y: float): float =
    result = 0.0
    var freq = 1.0.float
    var amp = 1.0.float

    for i in countup(1, octaves):
      result += noiseProc(x * freq, y * freq) * amp
      freq *= lacunarity
      amp *= gain


proc makeFractalNoiseProc*(noiseProc: noiseProc3D,
                           octaves: int,
                           lacunarity: float = 2.0,
                           gain: float = 0.5): noiseProc3D =
  ##  Creates and returns a ``proc`` that will generate 3D fractal
  ##  noise.
  ##
  ##  The returned ``proc``, when called, will sample ``noiseProc``
  ##  ``octave`` times and combine the results to generate the final
  ##  noise value. In each call, the sampling frequency is multiplied
  ##  by ``lacunarity`` and the amplitude is multiplied by ``gain``.
  result = proc(x, y, z: float): float =
    result = 0.0
    var freq = 1.0
    var amp = 1.0

    for i in countup(1, octaves):
      result += noiseProc(x * freq, y * freq, z * freq) * amp
      freq *= lacunarity
      amp *= gain


proc makeFractalNoiseProc*(noiseProc: noiseProc4D,
                           octaves: int,
                           lacunarity: float = 2.0,
                           gain: float = 0.5): noiseProc4D =
  ##  Creates and returns a ``proc`` that will generate 4D fractal
  ##  noise.
  ##
  ##  The returned ``proc``, when called, will sample ``noiseProc``
  ##  ``octave`` times and combine the results to generate the final
  ##  noise value. In each call, the sampling frequency is multiplied
  ##  by ``lacunarity`` and the amplitude is multiplied by ``gain``.
  result = proc(x, y, z, w: float): float =
    result = 0.0
    var freq = 1.0
    var amp = 1.0

    for i in countup(1, octaves):
      result += noiseProc(x * freq, y * freq, z * freq, w * freq) * amp
      freq *= lacunarity
      amp *= gain


#
# Unit tests
#

when defined(unittest):
  import chapunim.util.test
  import chapunim.noise.open_simplex_noise

# Just call the stuff, to be sure it compiles properly and doesn't
# crash. I don't know how to properly unit test this.
unittest:
  var noise = initOpenSimplexNoise(123)

  let fracNoise2d = makeFractalNoiseProc(
    proc(x, y: float): float = result = noise.eval(x, y),
    5)

  discard fracNoise2d(0.1, 0.2)

  let fracNoise3d = makeFractalNoiseProc(
    proc(x, y, z: float): float = result = noise.eval(x, y, z),
    4)

  discard fracNoise3d(0.1, 0.2, 0.3)

  let fracNoise4d = makeFractalNoiseProc(
    proc(x, y, z, w: float): float = result = noise.eval(x, y, z, w),
    6)

  discard fracNoise4d(0.1, 0.2, 0.3, 0.4)
