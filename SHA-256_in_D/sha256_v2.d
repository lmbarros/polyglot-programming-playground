

// Straightforward and inefficient right rotate
uint RightRotate(uint amount)(uint n)
{
   version (D_InlineAsm_X86)
   {
      asm
      {
         mov EAX, n      ;
         ror EAX, amount ;
         mov n, EAX      ;
      }

      return n;
   }
   else
   {
      foreach (i; 0..amount)
      {
         immutable uint lsb = n & 0x0000_0001;
         n >>= 1;
         n |= (lsb << 31);
      }

      return n;
   }
}

unittest
{
   // Notice the support for binary literals and underscores to separate groups
   // of digits.

   assert(RightRotate!(0)(0b0000_0000_1001_0000_0000_0000_0000_0000)
                       == 0b000_0000_1001_0000_0000_0000_0000_0000);

   assert(RightRotate!(1)(0b0000_0000_0000_0000_0000_0000_0000_0000)
                       == 0b0000_0000_0000_0000_0000_0000_0000_0000);

   assert(RightRotate!(1)(0b0000_1000_0000_0000_0000_0000_0000_0000)
                       == 0b0000_0100_0000_0000_0000_0000_0000_0000);

   assert(RightRotate!(1)(0b0000_0000_0000_0000_0000_0000_0000_0001)
                       == 0b1000_0000_0000_0000_0000_0000_0000_0000);

   assert(RightRotate!(1)(0b0000_1000_0000_1001_0000_0000_0000_0011)
                       == 0b1000_0100_0000_0100_1000_0000_0000_0001);

   assert(RightRotate!(2)(0b0000_1000_0000_1001_0000_0000_0000_0011)
                       == 0b1100_0010_0000_0010_0100_0000_0000_0000);

   assert(RightRotate!(3)(0b0000_1000_0000_1001_0000_0000_0000_0011)
                       == 0b0110_0001_0000_0001_0010_0000_0000_0000);

   assert(RightRotate!(11)(0b0000_0000_0000_0000_0000_0000_1000_0000)
                        == 0b0001_0000_0000_0000_0000_0000_0000_0000);
}


string HashToString(uint[8] hash)
{
   string ret;

   foreach(i; 0..8)
   {
      uint mask = 0xF0000000;

      foreach(j; 0..8)
      {
         auto n = ((hash[i] & mask) >> (4 * (7-j)));

         switch(n)
         {
            case 0: ret ~= '0'; break;
            case 1: ret ~= '1'; break;
            case 2: ret ~= '2'; break;
            case 3: ret ~= '3'; break;
            case 4: ret ~= '4'; break;
            case 5: ret ~= '5'; break;
            case 6: ret ~= '6'; break;
            case 7: ret ~= '7'; break;
            case 8: ret ~= '8'; break;
            case 9: ret ~= '9'; break;
            case 10: ret ~= 'a'; break;
            case 11: ret ~= 'b'; break;
            case 12: ret ~= 'c'; break;
            case 13: ret ~= 'd'; break;
            case 14: ret ~= 'e'; break;
            case 15: ret ~= 'f'; break;
            default: assert(false, "Invalid value");
         }

         mask >>= 4;
      }
   }

   return ret;
}

unittest
{
   uint[8] data = [ 0x00001111, 0x22223333, 0x44445555, 0x66667777,
                    0x88889999, 0xaaaabbbb, 0xccccdddd, 0xeeeeffff ];
   assert(HashToString(data) == "0000111122223333444455556666777788889999aaaabbbbccccddddeeeeffff");
}


/**
 * A class that computes the SHA-256 digest of data.
 * Example:
 * ---
 * auto sha256 = new SHA256();
 * sha256.addData(cast(ubyte[])"here's some data");
 * writefln("The hash is %s.", sha256.finish());
 * ---
 */
class SHA256
{
   public:
      /// Constructs the SHA256, leaving it ready to use.
      this()
      {
         reset();
      }

      /**
       * Resets the internal state of the SHA256 object, so that it can be used
       * as if it were brand new.
       */
      void reset()
      {
         messageSize_ = 0;

         // Believe it or not, these are the first 32 bits of the fractional
         // parts of the square roots of the first eight primes (2 to 19).
         hash_ = [ 0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
                   0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19 ];
      }

      /**
       * Adds more data to the SHA256 object. The digest is computed as data is
       * added.
       * Params:
       *    data = The data to be, er, digested.
       */
      void addData(ubyte[] data)
      in
      {
         // If we have 64 bytes in the chuck, processData() should have been
         // called already.
         assert(chunk_.length < 64);
      }
      body
      {
         // I am not going to be nominated for the Oscar of best code
         // optimization for this function...
         while (data.length > 0)
         {
            chunk_ ~= data[0];
            data = data[1..$];

            if (chunk_.length == 64)
            {
               processChunk();
               chunk_ = [ ];
            }
         }
      }

      /**
       * Finishes the digest computation. From this point on, no more data can
       * be added. (But you can call reset() and re-start using the same SHA256
       * object.)
       * Return: The digest, as a nice string of hexadecimal characters.
       */
      string finish()
      in
      {
         // If we have 64 bytes in the chuck, processData() should have been
         // called already.
         assert(chunk_.length < 64);
      }
      out
      {
         // All data should have been processed by the time we finish running
         // this function.
         assert(chunk_.length == 0);
      }
      body
      {
         messageSize_ += chunk_.length;

         // We don't have enough data in chunk_ to process it. So, let's add
         // some padding (as the algorithm requires us to do).

         // Append the bit '1' to the message (and some zeros, as required next)
         ubyte[] closingData;
         closingData ~= 0b1000_0000;

         // Append bits '0', almost until we end up with a full chunk. We should
         // only left 64 bits reserved for storing the message length.
         ulong finalMessageSize = messageSize_ + closingData.length;
         while (((finalMessageSize + 8) % 64) != 0)
         {
            closingData ~= 0b0000_0000;
            ++finalMessageSize;
         }

         // Append length of message, in bits, as 64-bit big-endian integer
         immutable messageSizeInBits = messageSize_ * 8;
         closingData ~= ((messageSizeInBits & 0xFF00_0000_0000_0000) >> 56);
         closingData ~= ((messageSizeInBits & 0x00FF_0000_0000_0000) >> 48);
         closingData ~= ((messageSizeInBits & 0x0000_FF00_0000_0000) >> 40);
         closingData ~= ((messageSizeInBits & 0x0000_00FF_0000_0000) >> 32);
         closingData ~= ((messageSizeInBits & 0x0000_0000_FF00_0000) >> 24);
         closingData ~= ((messageSizeInBits & 0x0000_0000_00FF_0000) >> 16);
         closingData ~= ((messageSizeInBits & 0x0000_0000_0000_FF00) >> 8);
         closingData ~=  (messageSizeInBits & 0x0000_0000_0000_00FF);

         // Process this last chunk of data
         assert((chunk_.length + closingData.length) * 8 == 512,
                "Should have a full chunk available");

         addData(closingData);

         // Voilà
         return HashToString(hash_);
      }

   private:

      /// Processes the current chunk (stored at chunk_).
      void processChunk()
      in
      {
         // We must have 512 bits of data in the current chunk to be able to
         // process it.
         assert(chunk_.length * 8 == 512);
      }
      body
      {
         messageSize_ += chunk_.length;

         uint w[64];

         // Break chunk into sixteen 32-bit big-endian words w[0..15]
         foreach (i; 0..16)
            w[i] = (chunk_[i * 4] << 24)
               | (chunk_[(i * 4) + 1] << 16)
               | (chunk_[(i * 4) + 2] << 8)
               | (chunk_[(i * 4) + 3]);


         // Extend the sixteen 32-bit words into sixty-four 32-bit words
         foreach (i; 16..64)
         {
            immutable uint s0 = RightRotate!(7)(w[i-15])
               ^ RightRotate!(18)(w[i-15])
               ^ (w[i-15] >> 3);
            immutable uint s1 = RightRotate!(17)(w[i-2])
               ^ RightRotate!(19)(w[i-2])
               ^ (w[i-2] >> 10);

            w[i] = w[i-16] + s0 + w[i-7] + s1;
         }

         // Initialize hash value for this chunk:
         uint a = hash_[0];
         uint b = hash_[1];
         uint c = hash_[2];
         uint d = hash_[3];
         uint e = hash_[4];
         uint f = hash_[5];
         uint g = hash_[6];
         uint h = hash_[7];

         // Main loop
         foreach(i; 0..64)
         {
            immutable uint s0 = RightRotate!(2)(a)
               ^ RightRotate!(13)(a)
               ^ RightRotate!(22)(a);
            immutable uint maj = (a & b) ^ (a & c) ^ (b & c);
            immutable uint t2 = s0 + maj;
            immutable uint s1 = RightRotate!(6)(e)
               ^ RightRotate!(11)(e)
               ^ RightRotate!(25)(e);
            immutable uint ch = (e & f) ^ ((~e) & g);
            immutable uint t1 = h + s1 + ch + k_[i] + w[i];

            h = g;
            g = f;
            f = e;
            e = d + t1;
            d = c;
            c = b;
            b = a;
            a = t1 + t2;
         }

         // Add this chunk's hash to result so far
         hash_[0] += a;
         hash_[1] += b;
         hash_[2] += c;
         hash_[3] += d;
         hash_[4] += e;
         hash_[5] += f;
         hash_[6] += g;
         hash_[7] += h;
      }

      uint messageSize_; // in bytes!

      uint[8] hash_; // eventually, the hash will be here

      // Table of round constants, which happen to be the first 32 bits of the
      // fractional parts of the cube roots of the first 64 primes (2 to 311).
      immutable uint[64] k_ = [
         0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
         0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
         0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
         0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
         0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
         0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
         0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
         0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
         0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
         0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
         0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
         0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
         0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
         0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
         0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
         0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2 ];

      // the next 64-bytes chunk to process; may contain less than 64 bytes if
      // there are bytes remaining from the previous addData().
      ubyte[] chunk_;

} // class SHA 256;


unittest
{
   auto sha256 = new SHA256();
   assert(sha256.finish() == "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855");
}

unittest
{
   auto sha256 = new SHA256();
   sha256.addData(cast(ubyte[])("The quick brown fox jumps over the lazy dog"));
   assert(sha256.finish() == "d7a8fbb307d7809469ca9abcb0082e4f8d5651e46d3cdb762d02d0bf37c9e592");
}

unittest
{
   auto sha256 = new SHA256();
   sha256.addData(cast(ubyte[])("The quick brown fox jumps over the lazy dog."));
   assert(sha256.finish() == "ef537f25c895bfa782526529a9b63d97aa631564d5d789c2b765448c8635fb6c");
}

unittest
{
   auto sha256 = new SHA256();
   string data;
   foreach (i; 0..2048)
      data ~= '!';
   sha256.addData(cast(ubyte[])(data));
   assert(sha256.finish() == "3e2e87448d8ed8a8cfeebc62d0201f3119648832d0030e228376d0826c4dd02c");
}



int main(string args[])
{
   import std.stdio;

   if (args.length != 2)
   {
      writefln("Usage: %s <file>", args[0]);
      return 1;
   }

   SHA256 sha256 = new SHA256();

   auto f = File(args[1], "rb");
   foreach (ubyte[] chunk; f.byChunk(2048))
      sha256.addData(chunk);

   immutable string digest = sha256.finish();

   writefln("%s  %s", digest, args[1]);

   return 0;
}
