use crate::structs::*;
use crate::utils::*; // For hex grid math
use rand::Rng;
use rand::seq::SliceRandom;
use std::collections::HashMap;
use godot::prelude::*; // For godot_print, clamp, etc.

use godot::builtin::Vector2i;

use crate::map::{remove_meat_from_tile_piles}; // Import helper functions

impl Animal {
    // --- Characteristic Calculations (from Animal_Characteristics.gd) ---
    fn get_diet_modifier(&self) -> f64 {
         1.0 + self.genes.food_preference.powf(1.5)
    }

    fn get_turns_to_change_tile(&self) -> i32 {
        if self.genes.speed < 0.33 { return 3; }
        else if self.genes.speed < 0.66 { return 2; }
        else { return 1; } // Should likely be 1 minimum? Let's adjust to min 1.
    }

    // Called during initialization/spawning
    pub fn set_characteristics(&mut self, params: &SimulationParameters) {
        self.age = 0;
        self.life_span = (((self.genes.size * 2.0).powi(2)) * 700.0 + 250.0) as i32;
        self.mass = self.genes.size; // Direct mapping in GDScript
        self.turns_to_change_tile = self.get_turns_to_change_tile();

        let base_activity_level = self.genes.speed.powf(1.3)
            + self.genes.mating_rate.powf(0.5)
            + self.genes.stealth.powf(0.6)
            + self.genes.detection.powf(0.9);
        let base_metabolic_rate = self.mass.powf(0.75); // Kleiber's Law

        let metabolic_rate = (base_metabolic_rate * base_activity_level) / params.normaliser;

        let diet_modifier = self.get_diet_modifier();
        self.food_consumption = metabolic_rate / diet_modifier.max(0.01); // Avoid div by zero
        self.water_consumption = self.food_consumption * 3.0;

        self.max_resources = (self.mass.powf(1.5)) / 2.0;

        // Initialize resources at half capacity
        self.nutrition = 0.5 * self.max_resources;
        self.hydration = 0.5 * self.max_resources;
        self.update_resource_norms(); // Calculate initial norms

        self.ready_to_mate = 0.0;

        // Default seek thresholds (can be overridden later if needed)
        self.seek_nutrition_norm = 0.3;
        self.seek_hydration_norm = 0.3;
    }

    // --- Animal Logic (Translated from Animal.gd) ---
    pub fn set_vore_type(&mut self) {
        if self.genes.food_preference > 0.75 { self.vore_type = VoreType::Carnivore; }
        else if self.genes.food_preference < 0.25 { self.vore_type = VoreType::Herbivore; }
        else { self.vore_type = VoreType::Omnivore; }
    }

    // Spawning logic - combines spawn_animal and parts of constructor logic
    pub fn spawn_new<R: Rng>(
        animal_id: i64,
        map_position: Vector2i,
        generation: i32,
        parent_1_genes: &AnimalGenes,
        parent_2_genes: &AnimalGenes,
        params: &SimulationParameters,
        rng: &mut R,
    ) -> Self {
        let genes = AnimalGenes::pass_down_genes(parent_1_genes, parent_2_genes, params, rng);
        let mut animal = Animal {
            animal_id,
            map_position,
            genes, // Temp value
            vore_type: VoreType::Omnivore, // Placeholder
            generation,
            is_moving: false,
            moving_to_tile_turns_remaining: 0,
            destination: Vector2i::ZERO, // Placeholder
            // Initialize other fields to defaults before set_characteristics
            age: 0,
            mass: 0.0, food_consumption: 0.0, water_consumption: 0.0, ready_to_mate: 0.0,
            life_span: 0, turns_to_change_tile: 1, max_resources: 0.0, nutrition: 0.0,
            nutrition_norm: 0.0, seek_nutrition_norm: 0.3, hydration: 0.0, hydration_norm: 0.0,
            seek_hydration_norm: 0.3,
            nutrition_gain_meat_this_turn: 0.0, nutrition_gain_plant_this_turn: 0.0,
        };
        animal.genes = AnimalGenes::pass_down_genes(parent_1_genes, parent_2_genes, params, rng); // Inherit genes
        animal.set_characteristics(params); // Set characteristics based on genes
        animal.set_vore_type(); // Set vore type based on genes
        animal
    }

    // For random animals
    pub fn spawn_random<R: Rng>(
    animal_id: i64,
    map_position: Vector2i,
    params: &SimulationParameters,
    rng: &mut R,
    ) -> Self {
        // generate a random animal by randomly generating genes
        let size = rng.gen_range(0.0..=1.0);
        let speed = rng.gen_range(0.0..=1.0);
        let food_preference = rng.gen_range(0.0..=1.0);
        let mating_rate = rng.gen_range(0.0..=1.0);
        let stealth = rng.gen_range(0.0..=1.0);
        let detection = rng.gen_range(0.0..=1.0);

        let mut genes = AnimalGenes::default();
        genes.set_genes(size, speed, food_preference, mating_rate, stealth, detection);

        let mut animal = Animal {
            animal_id,
            map_position,
            genes, // Temp value
            vore_type: VoreType::Omnivore, // Placeholder
            generation: 0, // Predetermined are gen 0
            is_moving: false,
            moving_to_tile_turns_remaining: 0,
            destination: Vector2i::ZERO, // Placeholder
            // Initialize other fields
            age: 0, mass: 0.0, food_consumption: 0.0, water_consumption: 0.0, ready_to_mate: 0.0,
            life_span: 0, turns_to_change_tile: 1, max_resources: 0.0, nutrition: 0.0,
            nutrition_norm: 0.0, seek_nutrition_norm: 0.3, hydration: 0.0, hydration_norm: 0.0,
            seek_hydration_norm: 0.3,
            nutrition_gain_meat_this_turn: 0.0, nutrition_gain_plant_this_turn: 0.0,
        };
        animal.genes.set_genes(size, speed, food_preference, mating_rate, stealth, detection); // Set genes properly
        animal.set_characteristics(params); // Set characteristics based on genes
        animal.ready_to_mate = rng.gen_range(0.2..=0.8); // Initialize with random readiness
        animal.set_vore_type(); // Set vore type based on genes
        animal
    }

    // For predetermined animals
    pub fn spawn_predetermined<R: Rng>(
    animal_id: i64,
    map_position: Vector2i,
    params: &SimulationParameters,
    rng: &mut R,
    ) -> Self {
        // construct_predetermined_animal_genes logic
        let size = rng.gen_range(0.47..=0.53);
        let speed = rng.gen_range(0.47..=0.53);
        let food_preference = rng.gen_range(0.17..=0.23);
        let mating_rate = rng.gen_range(0.27..=0.33);
        let stealth = rng.gen_range(0.17..=0.23);
        let detection = rng.gen_range(0.17..=0.23);

        let mut genes = AnimalGenes::default();
        genes.set_genes(size, speed, food_preference, mating_rate, stealth, detection);

        let mut animal = Animal {
            animal_id,
            map_position,
            genes, // Temp value
            vore_type: VoreType::Omnivore, // Placeholder
            generation: 0, // Predetermined are gen 0
            is_moving: false,
            moving_to_tile_turns_remaining: 0,
            destination: Vector2i::ZERO, // Placeholder
            // Initialize other fields
            age: 0, mass: 0.0, food_consumption: 0.0, water_consumption: 0.0, ready_to_mate: 0.0,
            life_span: 0, turns_to_change_tile: 1, max_resources: 0.0, nutrition: 0.0,
            nutrition_norm: 0.0, seek_nutrition_norm: 0.3, hydration: 0.0, hydration_norm: 0.0,
            seek_hydration_norm: 0.3,
            nutrition_gain_meat_this_turn: 0.0, nutrition_gain_plant_this_turn: 0.0,
        };
        animal.genes.set_genes(size, speed, food_preference, mating_rate, stealth, detection); // Set genes properly
        animal.set_characteristics(params); // Set characteristics based on genes
        animal.ready_to_mate = rng.gen_range(0.2..=0.8); // Initialize with random readiness
        animal.set_vore_type(); // Set vore type based on genes
        animal
    }


    pub fn resource_calc(&mut self) {
        self.nutrition -= self.food_consumption;
        self.hydration -= self.water_consumption;
    }

    pub fn update_resource_norms(&mut self) {
        if self.max_resources > 0.0 {
        self.nutrition_norm = (self.nutrition / self.max_resources).clamp(0.0, 1.0);
        self.hydration_norm = (self.hydration / self.max_resources).clamp(0.0, 1.0);
        } else {
            self.nutrition_norm = 0.0;
            self.hydration_norm = 0.0;
        }
    }

    pub fn update_animal_resources(&mut self) {
        self.resource_calc();
        self.update_resource_norms();
        // Accumulate readiness, capped at 1.0
        self.ready_to_mate = (self.ready_to_mate + self.genes.mating_rate / 125.0).min(1.0);
    }

    // remove_animal_from_world: Handled by the main simulation loop in lib.rs

    // kill_animal: Logic integrated into main simulation loop (death handling)

    pub fn fight<R: Rng> (
        &self, // Attacker
        defender: &Animal, // Defender
        rng: &mut R,
    ) -> Result<bool, ()>
    {
        let attacker_power = self.genes.size * self.genes.food_preference.sqrt();
        let defender_power = defender.genes.size * defender.genes.food_preference.sqrt();

        let stealth_roll = rng.gen_range(0.0..=(self.genes.stealth + defender.genes.detection)); // Inclusive range

        let mut final_attacker_power = attacker_power;

        if stealth_roll < self.genes.stealth { // Attacker not detected
            final_attacker_power *= 2.0; // Stealth bonus
        } else { // Attacker detected
            let speed_roll = rng.gen_range(0.0..=(self.genes.speed.powi(2) + defender.genes.speed.powi(2)));
            if speed_roll > self.genes.speed.powi(2) { // Prey got away
                return Ok(false); // Attacker effectively "lost" chase
            }
        }

        let total_power = final_attacker_power + defender_power;
        let attack_roll = rng.gen_range(0.0..=total_power.max(0.01)); // Avoid 0 range if total_power is 0

        if attack_roll < final_attacker_power { // Attacker wins
            Ok(true)
        } else { // Defender wins/survives
            Ok(false)
        }
    }

    // // Returns Ok(true) if attacker wins, Ok(false) if defender wins/escapes, Err if defender doesn't exist
    // pub fn fight<R: Rng>(
    //     &mut self, // Attacker
    //     defender_id: i64,
    //     animals: &HashMap<i64, Animal>, // Read-only access usually sufficient here
    //     rng: &mut R,
    // ) -> Result<bool, &'static str> {
    //     let Some(defender) = animals.get(&defender_id) else {
    //         return Err("Defender not found");
    //     };

    //     let attacker_power = self.genes.size * self.genes.food_preference.sqrt();
    //     let defender_power = defender.genes.size * defender.genes.food_preference.sqrt();

    //     let stealth_roll = rng.gen_range(0.0..=(self.genes.stealth + defender.genes.detection)); // Inclusive range

    //     let mut final_attacker_power = attacker_power;

    //     if stealth_roll < self.genes.stealth { // Attacker not detected
    //         final_attacker_power *= 2.0; // Stealth bonus
    //     } else { // Attacker detected
    //         let speed_roll = rng.gen_range(0.0..=(self.genes.speed.powi(2) + defender.genes.speed.powi(2)));
    //         if speed_roll > self.genes.speed.powi(2) { // Prey got away
    //             return Ok(false); // Attacker effectively "lost" chase
    //         }
    //     }

    //     let total_power = final_attacker_power + defender_power;
    //     let attack_roll = rng.gen_range(0.0..=total_power.max(0.01)); // Avoid 0 range if total_power is 0

    //     if attack_roll < final_attacker_power { // Attacker wins
    //         // Death/meat handled by caller
    //         Ok(true)
    //     } else { // Defender wins/survives
    //         self.nutrition -= 0.05 * self.max_resources; // Consequence for attacker losing
    //         Ok(false)
    //     }
    // }

    // Find IDs of animals on the current tile that can be hunted
    pub fn get_huntable_prey_ids<R: Rng>(
        &self,
        tile: &RustTileProperties,
        animals: &HashMap<i64, Animal>,
        rng: &mut R,
    ) -> Vec<i64> {
        tile.animal_ids.iter()
            .filter_map(|&prey_id| {
                if prey_id == self.animal_id { return None; } // Skip self

                let Some(prey_animal) = animals.get(&prey_id) else {
                    godot_warn!("Prey ID {} found on tile but not in animals map!", prey_id); // Log inconsistency
                    return None;
                };

                // Detection check
                let detection_roll = rng.gen_range(0.0..=(self.genes.detection + prey_animal.genes.stealth));
                if detection_roll < self.genes.detection { // Detected prey
                // Add size check? fight() handles mismatch, but could filter early
                // if prey_animal.genes.size < self.genes.size * 1.5 { Some(prey_id) } else { None }
                Some(prey_id)
                } else {
                None // Not detected
                }
            })
            .collect()
    }

    // Selects one huntable prey ID randomly
    pub fn get_random_huntable_prey_id<R: Rng>(
        &self,
        tile: &RustTileProperties,
        animals: &HashMap<i64, Animal>,
        rng: &mut R,
    ) -> Option<i64> {
        let potential_prey = self.get_huntable_prey_ids(tile, animals, rng);
        potential_prey.choose(rng).copied() // Choose random ID from Vec
    }

    // Get huntable scents on the current tile
    pub fn get_huntable_scents<'a>(
        &self,
        tile: &'a RustTileProperties,
        animals: &HashMap<i64, Animal>, // To check if scent owner is smaller/exists
    ) -> Vec<&'a AnimalScent> {
        tile.scent_trails.iter()
            .filter(|scent| {
                if scent.animal_id == self.animal_id { return false; } // Skip own scent
                // Check if animal exists and is smaller
                // TODO: change available hunting params from simple size comparison
                animals.get(&scent.animal_id)
                    .map_or(false, |animal| animal.genes.size < self.genes.size)
            })
            .collect()
    }

    // Selects one huntable scent randomly
    pub fn get_random_huntable_scent<'a, R: Rng>(
        &self,
        tile: &'a RustTileProperties,
        animals: &HashMap<i64, Animal>,
        rng: &mut R,
    ) -> Option<&'a AnimalScent> {
        let potential_scents = self.get_huntable_scents(tile, animals);
        potential_scents.choose(rng).copied()
    }

    // Eat meat logic, returns amount of meat resource consumed
    pub fn eat_meat(&mut self, tile: &mut RustTileProperties) {
        let meat_amount = tile.total_meat;
        let nutrition_needed = self.max_resources - self.nutrition;

        let meat_to_eat = meat_amount.min(nutrition_needed);
        // Call helper to actually remove meat from tile piles
        let meat_eaten = remove_meat_from_tile_piles(tile, meat_to_eat); // Assumes helper exists

        // update nutrition based on amount of food eaten and food type efficiency
        let food_type_efficiency = self.genes.food_preference.sqrt();
        let nutrition_gained = meat_eaten * food_type_efficiency;
        self.nutrition = (self.nutrition + nutrition_gained).min(self.max_resources);
        self.nutrition_gain_meat_this_turn += nutrition_gained; // Track for stats
    }

    // Eat plant matter logic
    pub fn eat_plant_matter(&mut self, tile: &mut RustTileProperties) {
        let plant_matter = tile.plant_matter;
        let nutrition_needed = self.max_resources - self.nutrition;

        let plant_eaten = plant_matter.min(nutrition_needed);
        tile.plant_matter -= plant_eaten;

        // update nutrition based on amount of food eaten and food type efficiency
        let food_type_efficiency = (1.0 - self.genes.food_preference).sqrt();
        let nutrition_gained = plant_eaten * food_type_efficiency;
        self.nutrition = (self.nutrition + nutrition_gained).min(self.max_resources);
        self.nutrition_gain_plant_this_turn += nutrition_gained; // Track for stats
    }

    // drink logic
    pub fn drink(&mut self, tile: &mut RustTileProperties) {
        if tile.hydration > 0.0 {
            let water_needed = self.max_resources - self.hydration;
            let water_gained = tile.hydration.min(water_needed);
            self.hydration = (self.hydration + water_gained).min(self.max_resources);
            tile.hydration -= water_gained;
        }
    }

    // --- Mating Logic ---
    pub fn determine_genetic_distance(&self, other_genes: &AnimalGenes) -> f64 {
        // (Same implementation as before)
        let mut similarity_sq_sum = 0.0;
        similarity_sq_sum += (self.genes.size - other_genes.size).powi(2);
        similarity_sq_sum += (self.genes.speed - other_genes.speed).powi(2);
        similarity_sq_sum += (3.0 * (self.genes.food_preference - other_genes.food_preference)).powi(2);
        similarity_sq_sum += (self.genes.mating_rate - other_genes.mating_rate).powi(2);
        similarity_sq_sum += (self.genes.stealth - other_genes.stealth).powi(2);
        similarity_sq_sum += (self.genes.detection - other_genes.detection).powi(2);
        similarity_sq_sum.sqrt()
    }

    pub fn can_mate_genetically(&self, other_genes: &AnimalGenes, params: &SimulationParameters) -> bool {
        let distance = self.determine_genetic_distance(other_genes);
        let similarity = 1.0 - (distance / params.max_genetic_distance.max(0.01));
        similarity > params.min_allowed_genetic_similarity // Using renamed param
    }

    pub fn can_mate_with_animal(&self, other: &Animal, params: &SimulationParameters) -> bool {
        other.ready_to_mate >= 1.0 && self.can_mate_genetically(&other.genes, params)
    }

    // Gets IDs of potential mates on the current tile
    pub fn get_potential_mate_ids<'a>(
        &self,
        tile: &'a RustTileProperties,
        animals: &'a HashMap<i64, Animal>,
        params: &SimulationParameters,
    ) -> Vec<i64> {
        tile.animal_ids.iter()
            .filter_map(|&mate_id| {
                if mate_id == self.animal_id { return None; }
                animals.get(&mate_id).and_then(|potential_mate| {
                    if self.can_mate_with_animal(potential_mate, params) { Some(mate_id) } else { None }
                })
            })
            .collect()
    }

    pub fn get_random_potential_mate_id<'a, R: Rng>(
        &self,
        tile: &'a RustTileProperties,
        animals: &'a HashMap<i64, Animal>,
        params: &SimulationParameters,
        rng: &mut R,
    ) -> Option<i64> {
        let potential_mates = self.get_potential_mate_ids(tile, animals, params);
        potential_mates.choose(rng).copied()
    }

     // Gets potential mate scents on the current tile
    pub fn get_potential_mate_scents<'a>(
        &self,
        tile: &'a RustTileProperties,
        animals: &'a HashMap<i64, Animal>,
        params: &SimulationParameters,
    ) -> Vec<&'a AnimalScent> {
        tile.scent_trails.iter()
            .filter(|scent| {
                if scent.animal_id == self.animal_id { return false; }
                animals.get(&scent.animal_id).map_or(false, |animal| {
                    // Check genetic compatibility based on scent owner
                    self.can_mate_genetically(&animal.genes, params)
                    // We don't know if they are ready_to_mate >= 1.0 from scent alone
                })
            })
            .collect()
    }

    // Selects one mate scent randomly
    pub fn get_random_potential_mate_scent<'a, R: Rng>(
        &self,
        tile: &'a RustTileProperties,
        animals: &'a HashMap<i64, Animal>,
        params: &SimulationParameters,
        rng: &mut R,
    ) -> Option<&'a AnimalScent> {
        let scents = self.get_potential_mate_scents(tile, animals, params);
        scents.choose(rng).copied()
    }


    // --- Movement ---
    pub fn begin_move_to_tile(&mut self, destination: Vector2i) {
        // TODO: Add bounds check using params.width/height if necessary? Assumed valid for now.
        self.moving_to_tile_turns_remaining = self.turns_to_change_tile.max(1); // Ensure min 1 turn
        self.is_moving = true;
        self.destination = destination;
    }

    // perform_move: Logic moved to main simulation loop in lib.rs

    // move_random: Needs context (map dimensions, Rng)
    pub fn move_random<R: Rng>(&mut self, params: &SimulationParameters, rng: &mut R) {
         let neighbours = get_neighbouring_tiles(self.map_position, params.width, params.height);
         if let Some(destination) = neighbours.choose(rng) {
             self.begin_move_to_tile(*destination);
         }
    }

    // --- Death Check ---
    pub fn animal_starved_of_resources(&self) -> bool {
        self.nutrition <= 0.0 || self.hydration <= 0.0
    }

     // --- Main Decision Logic for a single animal's turn ---
     // Returns an enum indicating the chosen action (Eat, Drink, Mate, Move, Hunt, FollowScent...)
     // This helps structure the main loop in lib.rs
    pub fn decide_action<R: Rng>(
        &self,
        tile: &RustTileProperties,
        animals: &HashMap<i64, Animal>,
        params: &SimulationParameters,
        rng: &mut R,
    ) -> Action {
        // Prioritize needs based on thresholds
        if self.nutrition_norm < self.seek_nutrition_norm && self.nutrition_norm <= self.hydration_norm {
            // Seek Food
            let mut chosen_strategy = VoreType::Omnivore; // Placeholder strategic choice
            if self.vore_type == VoreType::Omnivore { // Randomly choose strategy based on food preference
                chosen_strategy = if self.genes.food_preference < rng.gen_range(0.0..=1.0) {
                    VoreType::Carnivore
                } else {
                    VoreType::Herbivore
                };
            }
            else if self.vore_type == VoreType::Carnivore {
                chosen_strategy = VoreType::Carnivore; // Stick to carnivore
            }
            else {
                chosen_strategy = VoreType::Herbivore; // Stick to herbivore
            }

            match chosen_strategy {
                VoreType::Carnivore => {
                    if tile.total_meat > 0.0 { return Action::EatMeat; }
                    if let Some(prey_id) = self.get_random_huntable_prey_id(tile, animals, rng) {
                        return Action::Hunt(prey_id);
                    }
                    if let Some(scent) = self.get_random_huntable_scent(tile, animals, rng) {
                        return Action::FollowScent(scent.scent_direction);
                    }
                }
                VoreType::Herbivore | VoreType::Omnivore => {
                    if tile.plant_matter > 0.0 { return Action::EatPlant; }
                }
            }

            // If no action taken, move randomly
            return Action::MoveRandom;

        } else if self.hydration_norm < self.seek_hydration_norm {
            // Seek Water
            if tile.hydration > 0.0 {
                return Action::Drink;
            } else {
                // TODO: Implement searching for water tile/scent? For now, move randomly.
                return Action::MoveRandom;
            }
        } else if self.ready_to_mate >= 1.0 {
            // Seek Mate
            if let Some(mate_id) = self.get_random_potential_mate_id(tile, animals, params, rng) {
                return Action::Mate(mate_id);
            }
            if let Some(scent) = self.get_random_potential_mate_scent(tile, animals, params, rng) {
                return Action::FollowScent(scent.scent_direction);
            }
            // No mate/scent found, move randomly
            return Action::MoveRandom;
        } else {
            // Default Behavior: Move randomly
            return Action::MoveRandom;
        }
    }
}

// Enum to represent the chosen action
#[derive(Debug, Clone, Copy)]
pub enum Action {
    EatMeat,
    EatPlant,
    Drink,
    Hunt(i64), // Target prey ID
    Mate(i64), // Target mate ID
    FollowScent(Vector2i), // Target tile
    MoveRandom,
    // TODO: Could add Idle action
}
