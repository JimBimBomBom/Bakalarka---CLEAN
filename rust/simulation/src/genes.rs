use crate::structs::{AnimalGenes, SimulationParameters};
use rand::Rng;

impl AnimalGenes {
    // Not directly used in Animal.gd, but needed for initialization?
    pub fn generate<R: Rng>(rng: &mut R) -> Self {
        AnimalGenes {
            size: rng.gen_range(0.0..=1.0),
            speed: rng.gen_range(0.0..=1.0),
            food_preference: rng.gen_range(0.0..=1.0),
            mating_rate: rng.gen_range(0.0..=1.0),
            stealth: rng.gen_range(0.0..=1.0),
            detection: rng.gen_range(0.0..=1.0),
        }
    }

    pub fn set_genes(&mut self, size: f64, speed: f64, food_preference: f64, mating_rate: f64, stealth: f64, detection: f64) {
        self.size = size;
        self.speed = speed;
        self.food_preference = food_preference;
        self.mating_rate = mating_rate;
        self.stealth = stealth;
        self.detection = detection;
    }

    // Now takes parameters directly
    pub fn pass_down_genes<R: Rng>(parent_1: &AnimalGenes, parent_2: &AnimalGenes, params: &SimulationParameters, rng: &mut R) -> Self {
         AnimalGenes {
             size: Self::extract_gene(parent_1.size, parent_2.size, params, rng),
             speed: Self::extract_gene(parent_1.speed, parent_2.speed, params, rng),
             food_preference: Self::extract_gene(parent_1.food_preference, parent_2.food_preference, params, rng),
             mating_rate: Self::extract_gene(parent_1.mating_rate, parent_2.mating_rate, params, rng),
             stealth: Self::extract_gene(parent_1.stealth, parent_2.stealth, params, rng),
             detection: Self::extract_gene(parent_1.detection, parent_2.detection, params, rng),
         }
     }

    fn extract_gene<R: Rng>(parent_1_val: f64, parent_2_val: f64, params: &SimulationParameters, rng: &mut R) -> f64 {
         let from_parent_idx = rng.gen_range(0..=1); // 0 or 1
         let mut result = if from_parent_idx == 0 { parent_1_val } else { parent_2_val };

         let mut_roll = rng.gen::<f64>(); // 0.0 to 1.0
         if mut_roll < params.mutation_prob {
             let mutation_amount = rng.gen_range(-params.mutation_half_range..=params.mutation_half_range);
             result += mutation_amount;
             result = result.clamp(0.0, 1.0); // Clamp result between 0 and 1
         }
         result
     }
}
