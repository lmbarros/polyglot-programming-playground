/**
 * Fractal Brownian Motion. Combines several layers of noise to create
 * fractal-like noise.
 *
 * Authors: Leandro Motta Barros.
 *
 * See_Also:
 * https://code.google.com/p/fractalterraingeneration/wiki/Fractional_Brownian_Motion
 */

module syagrus.noise.fractional_brownian_motion;


/// A 1D noise function.
public alias double delegate(double) NoiseFunc1D_t;

/// A 2D noise function.
public alias double delegate(double, double) NoiseFunc2D_t;

/// A 3D noise function.
public alias double delegate(double, double, double) NoiseFunc3D_t;

/// A 4D noise function.
public alias double delegate(double, double, double, double) NoiseFunc4D_t;

/**
 * Creates and returns a function that will generate 1D noise using fractional
 * Brownian motion.
 *
 * The returned function, when called, will sample a given noise function a
 * number of times and combine the results to generate the final noise value.
 *
 * Parameters:
 *    noiseFunc = The function that will be used to generate the noise.
 *    octaves = The number of layers of noise to combine.
 *    frequency = The multiplier to use when sampling the noise function for
 *       the first octave. For each subsequent octave, this value is
 *       multiplied by lacunarity.
 *    amplitude = The multiplier to use for the noise value of the first
 *       octave. For each subsequent octave, this value is
 *       multiplied by gain.
 *    lacunarity = For each octave, the frequency is multiplied by this
 *       amount.
 *    gain = For each octave, the amplitude is multiplied by this amount.
 */
NoiseFunc1D_t MakeFBMFunc(
   NoiseFunc1D_t noiseFunc, uint octaves, double frequency, double amplitude,
   double lacunarity = 2.0, double gain = 0.5)
{
   return delegate(double x)
   {
      double sum = 0.0;
      double freq = frequency;
      double amp = amplitude;

      foreach(i; 0..octaves)
      {
         sum += noiseFunc(x * freq) * amp;
         freq *= lacunarity;
         amp *= gain;
      }

      return sum;
   };
}


/**
 * Creates and returns a function that will generate 2D noise using fractional
 * Brownian motion.
 *
 * The returned function, when called, will sample a given noise function a
 * number of times and combine the results to generate the final noise value.
 *
 * Parameters:
 *    noiseFunc = The function that will be used to generate the noise.
 *    octaves = The number of layers of noise to combine.
 *    frequency = The multiplier to use when sampling the noise function for
 *       the first octave. For each subsequent octave, this value is
 *       multiplied by lacunarity.
 *    amplitude = The multiplier to use for the noise value of the first
 *       octave. For each subsequent octave, this value is
 *       multiplied by gain.
 *    lacunarity = For each octave, the frequency is multiplied by this
 *       amount.
 *    gain = For each octave, the amplitude is multiplied by this amount.
 */
NoiseFunc2D_t MakeFBMFunc(
   NoiseFunc2D_t noiseFunc, uint octaves, double frequency, double amplitude,
   double lacunarity = 2.0, double gain = 0.5)
{
   return delegate(double x, double y)
   {
      double sum = 0.0;
      double freq = frequency;
      double amp = amplitude;

      foreach(i; 0..octaves)
      {
         sum += noiseFunc(x * freq, y * freq) * amp;
         freq *= lacunarity;
         amp *= gain;
      }

      return sum;
   };
}


/**
 * Creates and returns a function that will generate 3D noise using fractional
 * Brownian motion.
 *
 * The returned function, when called, will sample a given noise function a
 * number of times and combine the results to generate the final noise value.
 *
 * Parameters:
 *    noiseFunc = The function that will be used to generate the noise.
 *    octaves = The number of layers of noise to combine.
 *    frequency = The multiplier to use when sampling the noise function for
 *       the first octave. For each subsequent octave, this value is
 *       multiplied by lacunarity.
 *    amplitude = The multiplier to use for the noise value of the first
 *       octave. For each subsequent octave, this value is
 *       multiplied by gain.
 *    lacunarity = For each octave, the frequency is multiplied by this
 *       amount.
 *    gain = For each octave, the amplitude is multiplied by this amount.
 */
NoiseFunc3D_t MakeFBMFunc(
   NoiseFunc3D_t noiseFunc, uint octaves, double frequency, double amplitude,
   double lacunarity = 2.0, double gain = 0.5)
{
   return delegate(double x, double y, double z)
   {
      double sum = 0.0;
      double freq = frequency;
      double amp = amplitude;

      foreach(i; 0..octaves)
      {
         sum += noiseFunc(x * freq, y * freq, z * freq) * amp;
         freq *= lacunarity;
         amp *= gain;
      }

      return sum;
   };
}


/**
 * Creates and returns a function that will generate 4D noise using fractional
 * Brownian motion.
 *
 * The returned function, when called, will sample a given noise function a
 * number of times and combine the results to generate the final noise value.
 *
 * Parameters:
 *    noiseFunc = The function that will be used to generate the noise.
 *    octaves = The number of layers of noise to combine.
 *    frequency = The multiplier to use when sampling the noise function for
 *       the first octave. For each subsequent octave, this value is
 *       multiplied by lacunarity.
 *    amplitude = The multiplier to use for the noise value of the first
 *       octave. For each subsequent octave, this value is
 *       multiplied by gain.
 *    lacunarity = For each octave, the frequency is multiplied by this
 *       amount.
 *    gain = For each octave, the amplitude is multiplied by this amount.
 */
NoiseFunc4D_t MakeFBMFunc(
   NoiseFunc4D_t noiseFunc, uint octaves, double frequency, double amplitude,
   double lacunarity = 2.0, double gain = 0.5)
{
   return delegate(double x, double y, double z, double w)
   {
      double sum = 0.0;
      double freq = frequency;
      double amp = amplitude;

      foreach(i; 0..octaves)
      {
         sum += noiseFunc(x * freq, y * freq, z * freq, w * freq) * amp;
         freq *= lacunarity;
         amp *= gain;
      }

      return sum;
   };
}
