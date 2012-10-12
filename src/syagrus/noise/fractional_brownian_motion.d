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

/**
 * Combines several layers of noise to generate fractal-like noise. The current
 * implementation can generate 2D noise only.
 */
class FractionalBrownianMotionGenerator
{
   /**
    * The type for 2D noise-generating functions. Takes the two coordinates as
    * parameter, returns the noise value at those coordinates.
    */
   public alias double delegate(double, double) NoiseFunc_t;

   /**
    * Constructs the FractionalBrownianMotionGenerator.
    *
    * Parameters:
    *    noiseFunc = The function that will be used to generate the noise.
    *    octaves = The number of layers of noise to combine.
    *    frequency = The multiplier to use when sampling the noise function for
    *       the first octave. For each subsequent octave, this value is
    *       multiplied by lacunarity.
    *
    *    amplitude = The multiplier to use for the noise value of the first
    *       octave. For each subsequent octave, this value is
    *       multiplied by gain.
    *    lacunarity = For each octave, the frequency is multiplied by this
    *       amount.
    *    gain = For each octave, the amplitude is multiplied by this amount.
    */
   this(NoiseFunc_t noiseFunc, uint octaves, double frequency, double amplitude,
        double lacunarity = 2.0, double gain = 0.5)
   {
      noiseFunc_ = noiseFunc;
      octaves_ = octaves;
      frequency_ = frequency;
      amplitude_ = amplitude;
      lacunarity_ = lacunarity;
      gain_ = gain;
   }

   /**
    * Generates noise using fractional Brownian motion.
    *
    * Parameters:
    *    x = The desired x coordinate for the noise.
    *    y = The desired y coordinate for the noise.
    *
    * Return: The noise value at the requested coordinates. The range of the
    *    output depends on the parameters passed to the constructor. (The
    *    returned value is a sum of one value for each octave.)
    */
   public double noise(double x, double y)
   {
      double sum = 0.0;
      double freq = frequency_;
      double amp = amplitude_;

      foreach(i; 0..octaves_)
      {
         sum += noiseFunc_(x * freq, y * freq) * amp;
         freq *= lacunarity_;
         amp *= gain_;
      }

      return sum;
   }

   /// The function to use for generating noise.
   private immutable NoiseFunc_t noiseFunc_;

   /// The number of octaves (layers) to use.
   private immutable uint octaves_;

   /// The frequency multiplier for the first octave.
   private immutable double frequency_;

   /// The amplitude multiplier for the first octave.
   private immutable double amplitude_;

   /**
    * The frequency is multiplied by this amount for every octave after the
    * first one.
    */
   private immutable double lacunarity_;

   /**
    * The amplitude is multiplied by this amount for every octave after the
    * first one.
    */
   private immutable double gain_;
}
