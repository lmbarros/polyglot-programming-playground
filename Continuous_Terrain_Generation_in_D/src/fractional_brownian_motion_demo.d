/**
 * Fractional Brownian Noise Demo
 */

import derelict.sfml2.graphics;
import derelict.sfml2.window;
import syagrus.noise.simplex_noise;
import syagrus.noise.fractional_brownian_motion;
import std.c.stdlib;
import std.algorithm;
import std.exception;
import std.stdio;


SimplexNoiseGenerator SNG;
sfImage* Image;

enum Width = 400;
enum Height = 400;

uint Octaves = 2;
double Frequency = 1.0;
double Amplitude = 1.0;
double Lacunarity = 2.0;
double Gain = 0.5;


static this()
{
   DerelictSFML2Graphics.load();
   DerelictSFML2Window.load();

   SNG = new SimplexNoiseGenerator(SimplexNoiseGenerator.InitScheme.ORIGINAL);
}


void RedrawImage()
{
   auto fbm = MakeFBMFunc(
      delegate(x, y) { return SNG.noise(x, y); },
      Octaves,
      Frequency,
      Amplitude,
      Lacunarity,
      Gain);

   double min = double.max;
   double max = -double.max;

   double[Height][Width] realImage;

   // Create the image with real numbers
   foreach(i; 0 .. Width)
   {
      foreach(j; 0 .. Height)
      {
         immutable double ii = cast(double)(i) / Width;
         immutable double jj = cast(double)(j) / Height;

         immutable noise = fbm(ii, jj);

         if (noise < min)
            min = noise;
         if (noise > max)
            max = noise;

         realImage[i][j] = noise;
      }
   }

   // Normalize
   foreach(i; 0 .. Width)
   {
      foreach(j; 0 .. Height)
         realImage[i][j] = (realImage[i][j] + min) / (min + max);
   }

   // Create the ubyte image
   foreach(i; 0 .. Width)
   {
      foreach(j; 0 .. Height)
      {
         immutable ubyte noise = cast(ubyte)(realImage[i][j] * 255);
         sfImage_setPixel(Image, i, j, sfColor(noise, noise, noise, 255));
      }
   }
}



void HandleKeyPress(sfEvent event)
{
   enum delta = 0.05;

   void incVar(ref double var, double limit = double.max)
   {
      if (event.key.alt)
         var *= 2;
      else
         var += delta;

      var = min(var, limit);
   }

   void decVar(ref double var, double limit = -double.max)
   {
      if (event.key.alt)
         var /= 2;
      else
         var -= delta;

      var = max(var, limit);
   }

   void incVarU(ref uint var, uint limit = uint.max)
   {
      ++var;
      var = min(var, limit);
   }

   void decVarU(ref uint var, uint limit = uint.min)
   {
      --var;
      var = max(var, limit);
   }


   switch(event.key.code)
   {
      case sfKeyEscape:
         exit(0);
         break;

      // case sfKeyF1:
      //    Dimensions = 1;
      //    writeln("1D noise");
      //    break;

      // case sfKeyF2:
      //    Dimensions = 2;
      //    writeln("2D noise");
      //    break;

      // case sfKeyF3:
      //    Dimensions = 3;
      //    writeln("3D noise");
      //    break;

      // case sfKeyF4:
      //    Dimensions = 4;
      //    writeln("4D noise");
      //    break;

      case sfKeyF5:
         SNG = new SimplexNoiseGenerator(
            SimplexNoiseGenerator.InitScheme.RANDOM);
         writeln("Regenerated the noise generator");
         break;

      case sfKeyNum1:
         incVarU(Octaves, 10);
         writefln("Octaves = %s", Octaves);
         break;

      case sfKeyQ:
         decVarU(Octaves, 1);
         writefln("Octaves = %s", Octaves);
         break;

      // case sfKeyA:
      //    incVar(MaxX, int.max-1);
      //    writefln("MaxX = %s", MaxX);
      //    break;

      // case sfKeyZ:
      //    decVar(MaxX, int.min+1);
      //    writefln("MaxX = %s", MaxX);
      //    break;

      case sfKeyNum2:
         incVar(Frequency);
         writefln("Frequency = %s", Frequency);
         break;

      case sfKeyW:
         decVar(Frequency);
         writefln("Frequency = %s", Frequency);
         break;

      // case sfKeyS:
      //    incVar(MaxY, int.max-1);
      //    writefln("MaxY = %s", MaxY);
      //    break;

      // case sfKeyX:
      //    decVar(MaxY, int.min+1);
      //    writefln("MaxY = %s", MaxY);
      //    break;

      case sfKeyNum3:
         incVar(Amplitude);
         writefln("Amplitude = %s", Amplitude);
         break;

      case sfKeyE:
         decVar(Amplitude);
         writefln("Amplitude = %s", Amplitude);
         break;

      case sfKeyNum4:
         incVar(Lacunarity);
         writefln("Lacunarity = %s", Lacunarity);
         break;

      case sfKeyR:
         decVar(Lacunarity);
         writefln("Lacunarity = %s", Lacunarity);
         break;

      case sfKeyNum5:
         incVar(Gain);
         writefln("Gain = %s", Gain);
         break;

      case sfKeyT:
         decVar(Gain);
         writefln("Gain = %s", Gain);
         break;

      default:
         // do nothing (not even redraw the image!)
         return;
   }

   RedrawImage();
}


void main()
{
   sfVideoMode mode = { Width, Height, 32 };
   auto window =
      sfRenderWindow_create(
         mode, "Fractional Brownian Motion", sfDefaultStyle, null);
   enforce(window, "Failed to create sfRenderWindow");
   scope(exit)
      sfRenderWindow_destroy(window);

   Image = sfImage_create(Width, Height);
   enforce(Image, "Failed to create sfImage");
   scope(exit)
      sfImage_destroy(Image);

   auto texture = sfTexture_create(Width, Height);
   enforce(texture, "Failed to create sfTexture");
   scope(exit)
      sfTexture_destroy(texture);

   auto sprite = sfSprite_create();
   enforce(sprite, "Failed to create sfSprite");
   scope (exit)
      sfSprite_destroy(sprite);

   sfSprite_setTexture(sprite, texture, true);

   RedrawImage();

   while (sfRenderWindow_isOpen(window))
   {
      sfEvent event;

      while (sfRenderWindow_pollEvent(window, &event))
      {
         switch (event.type)
         {
            case sfEvtClosed:
               sfRenderWindow_close(window);
               break;

            case sfEvtKeyPressed:
               HandleKeyPress(event);
               break;

            default:
               // do nothing!
               break;
         }

         sfTexture_updateFromImage(texture, Image, 0, 0);
         sfRenderWindow_drawSprite(window, sprite, null);

         sfRenderWindow_display(window);
      }
   }
}
