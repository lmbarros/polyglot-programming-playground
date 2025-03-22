# Random Strings in Javascript / Node.js

Just trying some variations on the "generate a random string" theme. Mainly
trying to understand the performance implications of some (attempted)
micro-optimizations that shouldn't normally be worth to worry about.

Here's an example run from my Laptop (Intel Core i7-10750H, Linux 6.12.19,
Node.js 23.9.0):

```txt
Let's start just trying each of the functions.
[qBl2KGm/H9] naiveRandomString
[wfa8kvNz3G] arrayRandomString
[L5oMQxReUO] preallocatedArrayRandomString
[L1/C1frw2W] cryptoRandomString
[rH761MqVgU] preallocatedCryptoRandomString

Now let's go for some timings (for a total of 1000000 calls).

Timings for 10-character strings.
168.77428500000002 ms naiveRandomString
315.373288 ms arrayRandomString
331.908134 ms preallocatedArrayRandomString
1960.8763130000002 ms cryptoRandomString
1989.1733240000003 ms preallocatedCryptoRandomString

Timings for 100-character strings.
1381.051668 ms naiveRandomString
2690.662386 ms arrayRandomString
2560.810064000001 ms preallocatedArrayRandomString
4027.423078 ms cryptoRandomString
3821.498765999999 ms preallocatedCryptoRandomString

Timings for 1000-character strings.
12773.075530999999 ms naiveRandomString
25138.508511 ms arrayRandomString
23607.805202999996 ms preallocatedArrayRandomString
22012.02502300001 ms cryptoRandomString
19714.07955699999 ms preallocatedCryptoRandomString
```

From playing around with this for a while, I take that:

* The naive implementation (generate one character at a time, concatenate) wins.
  Pretty much always, generally by significant amounts. But more about this
  later.
* With arrays, preallocating it to the desired size is a bit faster than
  appending each element as we go. The difference is kinda marginal. Sometimes,
  especially for short strings (like in the case shown above), the
  non-preallocated case was actually faster. I believe these are just other
  factors (garbage collector or whatever) getting on the way.
* The crypto library is an interesting case.
  * First, of course, comparing it to the PRNG is an apples and oranges
    comparison.
  * For short-sized strings, using crypto is way slower, which is not
    surprising.
  * But as we go to longer strings, it actually starts to get competitive. I
    would guess the critical factor here is the trade-off between *n* calls to
    `Math.random()` versus one single call to `crypto.getRandomValues()`. Looks
    like at some point the overhead of making thousands of function calls
    overweighs the cost of making a single call (that still does *n* times as
    much work). I haven't looked deeper to confirm that.
