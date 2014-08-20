
module simd;


import core.simd;
import std.stdio;
import std.string;

//version = CPU_ONLY;


// CPU_ONLY version
version (CPU_ONLY)
{
   public struct Vec4f
   {
      public this(float x, float y, float z, float w)
      {
         _data = [ x, y, z, w ];
      }

      public string toString() const
      {
         return format("(%s %s %s %s)",
                       _data[0],
                       _data[1],
                       _data[2],
                       _data[3]);
      }

      private float[4] _data;
   }


   public struct Mat4f
   {
      public this(float a, float b, float c, float d,
                  float e, float f, float g, float h,
                  float i, float j, float k, float l,
                  float m, float n, float o, float p)
      {
         _data = [ a, b, c, d,
                   e, f, g, h,
                   i, j, k, l,
                   m, n, o, p ];
      }

      Vec4f opBinary(string op)(Vec4f rhs) const
         if (op == "*")
      {
         const v = rhs._data;
         const m = _data;

         return Vec4f(
            m[0]*v[0]  + m[1]*v[1]  + m[2]*v[2]  + m[3]*v[3],
            m[4]*v[0]  + m[5]*v[1]  + m[6]*v[2]  + m[7]*v[3],
            m[8]*v[0]  + m[9]*v[1]  + m[10]*v[2] + m[11]*v[3],
            m[12]*v[0] + m[13]*v[1] + m[14]*v[2] + m[15]*v[3]);
      }

      public string toString() const
      {
         return format("%s %s %s %s\n%s %s %s %s\n%s %s %s %s\n%s %s %s %s\n",
                       _data[0],  _data[1],  _data[2],  _data[3],
                       _data[4],  _data[5],  _data[6],  _data[7],
                       _data[8],  _data[9],  _data[10], _data[11],
                       _data[12], _data[13], _data[14], _data[15]);
      }

      private float[16] _data;
   }
}
else // SIMD version
{
   public struct Vec4f
   {
      public this(float x, float y, float z, float w)
      {
         _data.array = [ x, y, z, w ];
      }

      public string toString() const
      {
         return format("(%s %s %s %s)",
                       _data.array[0],
                       _data.array[1],
                       _data.array[2],
                       _data.array[3]);
      }

      private float4 _data;
   }


   public struct Mat4f
   {
      public this(float a, float b, float c, float d,
                  float e, float f, float g, float h,
                  float i, float j, float k, float l,
                  float m, float n, float o, float p)
      {
         _row0.array = [ a, b, c, d ];
         _row1.array = [ e, f, g, h ];
         _row2.array = [ i, j, k, l ];
         _row3.array = [ m, n, o, p ];
      }

      Vec4f opBinary(string op)(Vec4f rhs) const
         if (op == "*")
      {
         float4 a, b, c, d;
         a = __simd(XMM.DPPS, _row0, rhs._data, 0b1111_0001);
         b = __simd(XMM.DPPS, _row1, rhs._data, 0b1111_0010);
         c = __simd(XMM.DPPS, _row2, rhs._data, 0b1111_0100);
         d = __simd(XMM.DPPS, _row3, rhs._data, 0b1111_1000);

         Vec4f res;

         float4 t1 = __simd(XMM.ADDPS, a, b);
         float4 t2 = __simd(XMM.ADDPS, c, d);

         res._data = __simd(XMM.ADDPS, t1, t2);

         return res;
      }

      public string toString() const
      {
         const r0 = _row0.array;
         const r1 = _row1.array;
         const r2 = _row2.array;
         const r3 = _row3.array;

         return format("%s %s %s %s\n%s %s %s %s\n%s %s %s %s\n%s %s %s %s\n",
                       r0[0], r0[1], r0[2], r0[3],
                       r1[0], r1[1], r1[2], r1[3],
                       r2[0], r2[1], r2[2], r2[3],
                       r3[0], r3[1], r3[2], r3[3]);
      }

      private float4 _row0;
      private float4 _row1;
      private float4 _row2;
      private float4 _row3;
   }
}

Mat4f makeRandomMatrix()
{
   import std.random;
   return Mat4f(uniform(-1.0, 1.0), uniform(-1.0, 1.0), uniform(-1.0, 1.0), uniform(-1.0, 1.0),
                uniform(-1.0, 1.0), uniform(-1.0, 1.0), uniform(-1.0, 1.0), uniform(-1.0, 1.0),
                uniform(-1.0, 1.0), uniform(-1.0, 1.0), uniform(-1.0, 1.0), uniform(-1.0, 1.0),
                uniform(-1.0, 1.0), uniform(-1.0, 1.0), uniform(-1.0, 1.0), uniform(-1.0, 1.0));
}

Vec4f makeRandomVector()
{
   import std.random;
   return Vec4f(uniform(-1.0, 1.0), uniform(-1.0, 1.0), uniform(-1.0, 1.0), uniform(-1.0, 1.0));
}


void main()
{
   enum N = 10_000_000;

   Mat4f[] mats;
   Vec4f[] vecs;
   Vec4f[] results;

   mats.length = N;
   vecs.length = N;
   results.length = N;

   foreach (i; 0..N)
   {
      mats[i] = makeRandomMatrix();
      vecs[i] = makeRandomVector();
   }

   import std.datetime;
   import std.random;

   StopWatch sw;
   sw.start();

   foreach (i; 0..N)
      results[i] = mats[i] * vecs[i];

   sw.stop();

   writefln("Some result = %s", results[uniform!("[]")(0,N)]);

   writefln("Time to compute: %s ms", sw.peek().msecs);

   // auto m = Mat4f(2, 3, 9, 2,
   //                5, 2, 2, 8,
   //                1, 2, 3, 8,
   //                7, 5, 3, 2);
   // auto v = Vec4f(8, 3, 6, 2);

   // writefln("%s", m * v); // 83, 74, 48, 93
}
