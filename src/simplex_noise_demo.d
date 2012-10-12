/**
 * Simplex Noise Demo
 */

import derelict.sfml2.graphics;
import derelict.sfml2.window;
import noise.simplex_noise;
import std.c.stdlib;
import std.algorithm;
import std.exception;
import std.stdio;


SimplexNoiseGenerator SNG;
sfImage* Image;

enum Width = 400;
enum Height = 400;
int Dimensions = 2;
double MinX = 0.0;
double MaxX = 1.0;
double MinY = 0.0;
double MaxY = 1.0;
double TheZ = 0.5;
double TheW = 0.5;


static this()
{
   DerelictSFML2Graphics.load();
   DerelictSFML2Window.load();

   SNG = new SimplexNoiseGenerator();
}


void RedrawImage()
{
   foreach(i; 0 .. Width)
   {
      foreach(j; 0 .. Height)
      {
         immutable double ii = MinX + (cast(double)(i) / Width) * MaxX;
         immutable double jj = MinY + (cast(double)(j) / Height) * MaxY;

         ubyte noise;

         switch(Dimensions)
         {
            case 1:
               noise = cast(ubyte)(SNG.noise(ii) * 255);
               break;

            case 2:
               noise = cast(ubyte)(SNG.noise(ii, jj) * 255);
               break;

            case 3:
               noise = cast(ubyte)(SNG.noise(ii, jj, TheZ) * 255);
               break;

            case 4:
               noise = cast(ubyte)(SNG.noise(ii, jj, TheZ, TheW) * 255);
               break;

            default:
               assert(false, "Can't happen");
         }

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


   switch(event.key.code)
   {
      case sfKeyEscape:
         exit(0);
         break;

      case sfKeyF1:
         Dimensions = 1;
         writeln("1D noise");
         break;

      case sfKeyF2:
         Dimensions = 2;
         writeln("2D noise");
         break;

      case sfKeyF3:
         Dimensions = 3;
         writeln("3D noise");
         break;

      case sfKeyF4:
         Dimensions = 4;
         writeln("4D noise");
         break;

      case sfKeyNum1:
         incVar(MinX, int.max-1);
         writefln("MinX = %s", MinX);
         break;

      case sfKeyQ:
         decVar(MinX, int.min+1);
         writefln("MinX = %s", MinX);
         break;

      case sfKeyA:
         incVar(MaxX, int.max-1);
         writefln("MaxX = %s", MaxX);
         break;

      case sfKeyZ:
         decVar(MaxX, int.min+1);
         writefln("MaxX = %s", MaxX);
         break;

      case sfKeyNum2:
         incVar(MinY, int.max-1);
         writefln("MinY = %s", MinY);
         break;

      case sfKeyW:
         decVar(MinY, int.min+1);
         writefln("MinY = %s", MinY);
         break;

      case sfKeyS:
         incVar(MaxY, int.max-1);
         writefln("MaxY = %s", MaxY);
         break;

      case sfKeyX:
         decVar(MaxY, int.min+1);
         writefln("MaxY = %s", MaxY);
         break;

      case sfKeyNum3:
         incVar(TheZ);
         writefln("TheZ = %s", TheZ);
         break;

      case sfKeyE:
         decVar(TheZ);
         writefln("TheZ = %s", TheZ);
         break;

      case sfKeyNum4:
         TheW += delta;
         writefln("TheW = %s", TheW);
         break;

      case sfKeyR:
         TheW -= delta;
         writefln("TheW = %s", TheW);
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
      sfRenderWindow_create(mode, "Simplex Noise", sfDefaultStyle, null);
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
