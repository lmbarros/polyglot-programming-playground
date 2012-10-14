/**
 * Terrain Demo
 */

import derelict.sfml2.graphics;
import derelict.sfml2.window;
import syagrus.noise.simplex_noise;
import syagrus.noise.fractional_brownian_motion;
import std.c.stdlib;
import std.algorithm;
import std.conv;
import std.exception;
import std.math;
import std.stdio;


SimplexNoiseGenerator SNG;
sfImage* Image;

enum Width = 965;
enum Height = 600;

uint Octaves = 8;
double Frequency = 1.5;
double Amplitude = 1.0;
double Lacunarity = 1.5;
double Gain = 0.75;
double SeaLevel = 0.75;


static this()
{
   DerelictSFML2Graphics.load();
   DerelictSFML2Window.load();

   SNG = new SimplexNoiseGenerator(SimplexNoiseGenerator.InitScheme.ORIGINAL);
}


sfColor GetColor(double height)
{
   struct hc // height & color
   {
      double height;
      sfColor color;
   }

   immutable hc[] hcs = [
      { 0.0, sfColor(10, 200, 50, 255) },   // light green
      { 0.35, sfColor(8, 150, 40, 255) },   // dark green
      { 0.5, sfColor(255, 240, 25, 255) },  // yellow
      { 0.65, sfColor(133, 94, 43, 255) },  // brown
      { 0.9, sfColor(166, 120, 60, 255) },  // still brown
      { 1.0, sfColor(220, 220, 220, 255) }, // light gray
      ];

   sfColor mix(const ref sfColor c1, const ref sfColor c2, double ratio)
   in
   {
      assert(ratio >= 0.0, "ratio out of range: " ~ to!string(ratio));
      assert(ratio <= 1.0, "ratio out of range: " ~ to!string(ratio));
   }
   body
   {
      immutable w1 = ratio;
      immutable w2 = 1.0 - ratio;
      return sfColor(cast(ubyte)(c1.r * w1 + c2.r * w2),
                     cast(ubyte)(c1.g * w1 + c2.g * w2),
                     cast(ubyte)(c1.b * w1 + c2.b * w2),
                     cast(ubyte)(c1.a * w1 + c2.a * w2));
   }

   immutable ubyte noise = cast(ubyte)(height * 255);

   if (height < SeaLevel)
   {
      immutable deepWater = sfColor(10, 20, 125, 255);
      immutable shallowWater = sfColor(30, 50, 200, 255);
      immutable r = height / SeaLevel;
      return mix(shallowWater, deepWater, r);
   }

   immutable aslHeight = (height - SeaLevel) / (1.0 - SeaLevel);

   size_t largerIndex;
   foreach(i, e; hcs)
   {
      if (e.height == aslHeight)
      {
         return e.color;
      }
      else if (e.height > aslHeight)
      {
         largerIndex = i;
         break;
      }
   }

   auto sh = hcs[largerIndex - 1].height; // small height
   auto lh = hcs[largerIndex].height;     // large height
   auto r = (aslHeight - sh) / (lh - sh);

   return mix(hcs[largerIndex].color, hcs[largerIndex - 1].color, r);
}


void GetCirclePoint(
   double cx, double cy, double radius, double t, out double x, out double y)
{
   t *= 2 * PI;

   x = cx + radius * cos(t);
   y = cy + radius * sin(t);
}


void RedrawImage()
{
   auto fbm = MakeFBMFunc(
      delegate(x, y, z) { return SNG.noise(x, y, z); },
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

         immutable cx = 0.0;
         immutable cy = 0.0;
         immutable radius = 0.42;
         immutable t = ii;
         double texX;
         double texY;

         // The idea of sampling a cylinder to get a tile-able 2D texture came
         // from an article by Joshua Tippetts (he samples a 4D noise function
         // to create 2D noise tile-able in both axes, but the idea is the
         // same): http://www.gamedev.net/blog/33/entry-2138456-seamless-noise
         GetCirclePoint(cx, cy, radius, t, texX, texY);
         immutable noise = fbm(texX, texY, jj);

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
         sfImage_setPixel(Image, i, j, GetColor(realImage[i][j]));
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

      case sfKeyNum6:
         incVar(SeaLevel);
         writefln("SeaLevel = %s", SeaLevel);
         break;

      case sfKeyY:
         decVar(SeaLevel);
         writefln("SeaLevel = %s", SeaLevel);
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
         mode, "Terrain", sfDefaultStyle, null);
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
