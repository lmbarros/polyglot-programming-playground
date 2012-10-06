
import noise.simplex_noise;
import std.stdio;

int n(double x, double y)
{
   double v = SimplexNoise(x, y, 4.3);
   return cast(int)(((v + 1.0) / 2.0) * 255);
}

void main()
{
   enum w = 2000;
   enum h = 2000;

   writeln("P2");
   writefln("%s", w);
   writefln("%s", h);
   writeln("255");

   double ww = w;
   double hh = h;
   foreach(i; 0..w)
   {
      foreach(j; 0..h)
         writef("%s ", n(i/hh, j/ww));

      writeln("");
   }
}
