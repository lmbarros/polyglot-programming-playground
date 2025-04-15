//
// The functions. Generate a string of `length` random characters drawn from
// `alphabet`.
//

function naiveRandomString(length, alphabet) {
  let result = '';
  const alphabetLength = alphabet.length;

  for (let i = 0; i < length; i++) {
    const randomIndex = Math.floor(Math.random() * alphabetLength);
    result += alphabet[randomIndex];
  }

  return result;
}

function arrayRandomString(length, alphabet) {
  const result = [];
  const alphabetLength = alphabet.length;

  for (let i = 0; i < length; i++) {
    const randomIndex = Math.floor(Math.random() * alphabetLength);
    result.push(alphabet[randomIndex]);
  }

  return result.join('');
}

function preallocatedArrayRandomString(length, alphabet) {
  const result = Array(length);
  const alphabetLength = alphabet.length;

  for (let i = 0; i < length; i++) {
    const randomIndex = Math.floor(Math.random() * alphabetLength);
    result[i] = alphabet[randomIndex];
  }

  return result.join('');
}

function cryptoRandomString(length, alphabet) {
  const result = [];
  const alphabetLength = alphabet.length;
  const randomBytes = new Uint8Array(length);
  crypto.getRandomValues(randomBytes);

  for (let i = 0; i < length; i++) {
    const byte = randomBytes[i];
    result.push(alphabet[byte % alphabetLength]); // modulo bias here!
  }

  return result.join('');
}

function preallocatedCryptoRandomString(length, alphabet) {
  const result = Array(length);
  const alphabetLength = alphabet.length;
  const randomBytes = new Uint8Array(length);
  crypto.getRandomValues(randomBytes);

  for (let i = 0; i < length; i++) {
    const byte = randomBytes[i];
    result[i] = alphabet[byte % alphabetLength]; // modulo bias here!
  }

  return result.join('');
}


//
// The main script.
//

const allFuncs = [
  naiveRandomString,
  arrayRandomString,
  preallocatedArrayRandomString,
  cryptoRandomString,
  preallocatedCryptoRandomString,
];

const base64Alphabet = '1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ+/';

console.log(`Let's start just trying each of the functions.`);

for (let f of allFuncs) {
  console.log(`[${f(10, base64Alphabet)}] ${f.name}`);
}

const N = 1_000_000;
console.log();
console.log(`Now let's go for some timings (for a total of ${N} calls).`);

for (let len of [10, 100, 1000]) {
  console.log();
  console.log(`Timings for ${len}-character strings.`);

  for (let f of allFuncs) {
    const start = performance.now();
    for (i = 0; i < N; ++i) {
      f(len, base64Alphabet);
    }
    const totalTime = (performance.now() - start);
    console.log(`${totalTime} ms ${f.name}`);
  }
}
