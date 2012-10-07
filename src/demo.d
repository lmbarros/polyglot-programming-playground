/**
 * @file
 * <...file contents description here...>
 *
 * @author Leandro Motta Barros
 */

import noise.simplex_noise;
import std.stdio;

int n(double x, double y)
{
   double v = SimplexNoise(x, y, 4.3);
   return cast(int)(((v + 1.0) / 2.0) * 255);
}

void main()
{
   enum w = 200;
   enum h = 200;

   writeln("P2");
   writefln("%s", w);
   writefln("%s", h);
   writeln("255");

   double ww = 50;
   double hh = 50;
   foreach(i; 0..w)
   {
      foreach(j; 0..h)
         writef("%s ", n(i/hh, j/ww));

      writeln("");
   }
}
