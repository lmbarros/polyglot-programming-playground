// Converting a PCG random number generator to Rust. Specifically, the pcg64s
// variant. Basing this on the C code: https://github.com/imneme/pcg-c

// Not trying to make this interoperable with any existing standard Rust
// random number generation mechanism.

// Missing advance() and bounded_random().

use std::num::Wrapping;

const MULTIPLIER: Wrapping<u128> = Wrapping((2549297995355413924 << 64) + 4865540595714422341);
const INCREMENT: Wrapping<u128> = Wrapping((6364136223846793005 << 64) + 1442695040888963407);

pub struct Rand {
    state: Wrapping<u128>,
}

impl Rand {
    pub fn new(seed: u128) -> Rand {
        let mut rng: Rand = Rand { state: Wrapping(0) };
        rng.seed(seed);
        return rng;
    }

    pub fn seed(&mut self, seed: u128) {
        self.state = Wrapping(0);
        self.step();
        self.state += seed;
        self.step();
    }

    pub fn random(&mut self) -> u64 {
        self.step();

        let s = self.state.0;
        let sl = s as u64;
        let sh = (s >> 64) as u64;
        // Original code shifts by 122. Here I shift by 58 = 122 - 64 because
        // taking the high-bits is already like shifting right by 64.
        let rotate_amount = (sh >> 58) as u32;
        (sh ^ sl).rotate_right(rotate_amount) as u64
    }

    fn step(&mut self) {
        self.state = self.state * MULTIPLIER + INCREMENT;
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    // Compare values with the ones generated by the C code.
    #[test]
    fn test_random() {
        let mut rng = Rand::new(1234);
        let mut vv = [0; 10];
        for v in vv.iter_mut() {
            *v = rng.random();
        }
        assert_eq!(
            vv,
            [
                9264802780032662508,
                4543764045635414863,
                2780558434653625935,
                17582746484101160380,
                12507048989320892151,
                16781239697739265712,
                5716587679137363963,
                4409406126455307673,
                14595074001431580880,
                217083827602160384,
            ]
        );

        rng.seed(4321);
        for v in vv.iter_mut() {
            *v = rng.random();
        }
        assert_eq!(
            vv,
            [
                17555971032251967940,
                4035364595360051946,
                16632746456647882899,
                14270216637996151530,
                15130667115467907616,
                1293515201678807029,
                115934655796610739,
                4010009379713060202,
                8871556732344088523,
                5342686612107944297,
            ]
        );
    }
}
