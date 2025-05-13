mod animal;
mod genes; // Needed for animal logic transitively
mod map;
mod structs;
mod utils; // Needed for map/animal logic transitively

// --- Imports ---
use godot::prelude::*; // Main gdext import
use rand::prelude::SliceRandom;
use rand::rngs::ThreadRng;
use std::collections::HashMap;
use std::time::Instant; // For timing diagnostics // <-- FIX: Import trait for .choose()

use rayon::prelude::*; // Import rayon traits - needed for parallel processing

// Use items from our modules
use crate::animal::Action; // Import specific types needed here
use crate::map::{add_meat_to_tile_piles, biome_to_int, int_to_biome, replenish_tile};
use crate::structs::{
    Animal,
    AnimalGenes,
    AnimalScent,
    AnimalStatistics,
    BiomeType,
    Meat,
    RustTileProperties,
    SimulationParameters,
    VoreType, // Import structs needed here
    WorldMap,
}; // Import helper functions

// --- Simulation Struct ---
#[derive(GodotClass)]
#[class(init)]//, base=RefCounted)]
pub struct Simulation {
    parameters: Option<SimulationParameters>,
    world_map: WorldMap,
    animals: HashMap<i64, Animal>,
    stats: AnimalStatistics,
    rng: ThreadRng,
    next_animal_id: i64,
}

// --- Godot API Implementation ---
#[godot_api]
impl Simulation {
    fn init() -> Self {
        godot_print!("Rust Simulation Core initializing...");
        Self {
            parameters: None,
            world_map: HashMap::new(),
            animals: HashMap::new(),
            stats: AnimalStatistics::default(),
            rng: rand::thread_rng(), // Use standard rand function
            next_animal_id: 0,
        }
    }

    // --- Private Helper Functions ---

    // Used for map showcase of animal movement
    #[func]
    fn get_tile_animal_counts(&self) -> Dictionary {
        let mut counts_dict = Dictionary::new();
        for (pos, tile_data) in &self.world_map {
            let count = tile_data.animal_ids.len() as i64; // Get count as i64
            counts_dict.set(Variant::from(*pos), Variant::from(count));
        }
        counts_dict
    }

    // Used for logging purposes.
    #[func]
    fn get_all_animal_data(&self) -> VariantArray { // Kept original name
        let mut animal_array = VariantArray::new();

        for animal in self.animals.values() {
            let mut animal_dict = Dictionary::new();

            // 1. Use "id" key for animal_id
            animal_dict.set("id", Variant::from(animal.animal_id));

            // 2. Add vore_type (Enum as i32)
            animal_dict.set("vore_type", Variant::from(animal.vore_type as i32));

            // 3. Add age (i32)
            animal_dict.set("age", Variant::from(animal.age as i32));

            // 4. Add genes (Struct as nested Dictionary)
            let mut genes_dict = Dictionary::new();
            genes_dict.set("size", Variant::from(animal.genes.size));
            genes_dict.set("speed", Variant::from(animal.genes.speed));
            genes_dict.set("food_preference", Variant::from(animal.genes.food_preference)); // Match GDScript spelling if needed for logger consistency
            genes_dict.set("mating_rate", Variant::from(animal.genes.mating_rate));
            genes_dict.set("stealth", Variant::from(animal.genes.stealth));
            genes_dict.set("detection", Variant::from(animal.genes.detection));
            // Note: Intimidation gene missing from AnimalGenes struct based on provided GDScript

            animal_dict.set("genes", Variant::from(genes_dict));

            animal_array.push(&Variant::from(animal_dict));
        }
        animal_array
    }

    // Parses STATIC tile data from a Godot Tile_Properties OBJECT and initializes dynamic fields
    fn parse_and_initialize_tile_properties(tile_object: &Gd<RefCounted>) -> Option<RustTileProperties> {
        // Helper to get f64 property or default
        fn get_f64_prop(obj: &Gd<RefCounted>, key: &str, default: f64) -> f64 {
            obj.get(key).try_to::<f64>().unwrap_or_else(|e| {
                godot_warn!("Failed to get/convert property '{}': {:?}. Using default.", key, e);
                default
            })
        }
        // Helper to get i32 property or default
        fn get_i32_prop(obj: &Gd<RefCounted>, key: &str, default: i32) -> i32 {
             obj.get(key).try_to::<i64>().map(|v| v as i32).unwrap_or_else(|e| { // Godot int is i64
                godot_warn!("Failed to get/convert property '{}': {:?}. Using default.", key, e);
                default
             })
        }

        // Extract static properties using .get("property_name")
        // Ensure property names match EXACTLY with Tile_Properties.gd variable names
        let temperature = get_f64_prop(tile_object, "temperature", 0.5);
        let moisture = get_f64_prop(tile_object, "moisture", 0.5);
        // Assuming 'biome' property stores the enum value as an integer
        let biome_int = get_i32_prop(tile_object, "biome", -1); // Use -1 for Uninitialized default
        let biome = int_to_biome(biome_int);

        // Check if essential data was retrieved reasonably (e.g., biome is not Uninitialized maybe?)
        // You might add more validation here if needed.
        if biome == BiomeType::Uninitialized && biome_int != -1 {
             godot_warn!("Tile has potentially invalid biome integer: {}", biome_int);
             // Decide whether to proceed or return None
        }


        // Calculate derived static properties (same logic as before)
        let max_hydration = moisture / 2.0;
        let max_plant_matter = (moisture.min(temperature)) / 4.0;
        let plant_matter_gain = max_plant_matter / 8.0;
        // Get spoil rate property if it exists, otherwise calculate
        let meat_spoil_rate = get_f64_prop(tile_object, "meat_spoil_rate", 1.0 / (temperature * 7.0).max(0.01));


        // Initialize dynamic properties (same as before)
        let initial_plant_matter = max_plant_matter / 2.0;
        let initial_hydration = max_hydration;

        Some(RustTileProperties {
            biome,
            temperature,
            moisture,
            max_hydration,
            max_plant_matter,
            plant_matter_gain,
            meat_spoil_rate,

            animal_ids: Vec::new(),
            scent_trails: Vec::new(),
            plant_matter: initial_plant_matter,
            meat_in_rounds: Vec::new(),
            total_meat: 0.0,
            hydration: initial_hydration,
        })
    }

    // Serializes only the animal_ids for Godot
    fn serialize_minimal_tile_to_dict(&self, tile_data: &RustTileProperties) -> Dictionary {
        let mut dict = Dictionary::new();
        dict.set(
            "animal_ids",
            Variant::from(PackedInt64Array::from_iter(
                tile_data.animal_ids.iter().cloned(),
            )),
        );
        dict
    }

    // Serializes full stats struct to Godot Dictionary
    fn serialize_stats_to_dict(&self, stats: &AnimalStatistics) -> Dictionary {
        let mut dict = Dictionary::new();
        dict.set("animal_count", stats.animal_count);
        dict.set("speed_avg", stats.speed_avg);
        dict.set("speed_range", stats.speed_range);
        dict.set("mating_rate_avg", stats.mating_rate_avg);
        dict.set("mating_rate_range", stats.mating_rate_range);
        dict.set("food_preference_avg", stats.food_preference_avg);
        dict.set("food_preference_range", stats.food_preference_range);
        dict.set("size_avg", stats.size_avg);
        dict.set("size_range", stats.size_range);
        dict.set("stealth_avg", stats.stealth_avg);
        dict.set("stealth_range", stats.stealth_range);
        dict.set("detection_avg", stats.detection_avg);
        dict.set("detection_range", stats.detection_range);
        dict.set("animal_nutrition_avg", stats.animal_nutrition_avg);
        dict.set("animal_hydration_avg", stats.animal_hydration_avg);
        dict.set("animal_ready_to_mate_avg", stats.animal_ready_to_mate_avg);
        dict.set("animal_deaths_age", stats.animal_deaths_age);
        dict.set("animal_deaths_starvation", stats.animal_deaths_starvation);
        dict.set("animal_deaths_dehydration", stats.animal_deaths_dehydration);
        dict.set("animal_deaths_predation", stats.animal_deaths_predation);
        // <-- FIX: Use correct field names from AnimalStatistics struct
         dict.set("nutrition_from_meat", stats.nutrition_from_meat);
         dict.set("nutrition_from_plants", stats.nutrition_from_plants);
        dict
    }

    // --- Exposed Functions ---

      #[func]
    fn set_map_for_rust(&mut self, map_variant: Variant) {
        let Ok(godot_dict) = Dictionary::try_from_variant(&map_variant) else {
            godot_error!("set_map_for_rust: Input is not a Dictionary.");
            return;
        };

        godot_print!("Setting map from Godot dictionary ({} entries)...", godot_dict.len());
        self.world_map.clear();
        self.animals.clear();
        self.stats = AnimalStatistics::default();
        self.next_animal_id = 0;

        // godot_print!("Rust:\n {}", godot_dict); // Keep for debugging if needed

        for (key, value) in godot_dict.iter_shared() {
            let Ok(pos) = Vector2i::try_from_variant(&key) else {
                godot_warn!("set_map_for_rust: Invalid key in map dictionary: {:?}", key);
                continue;
            };
            // <-- FIX: Try to convert value to Gd<RefCounted> (or Object) instead of Dictionary
            let Ok(tile_object) = Gd::<RefCounted>::try_from_variant(&value) else {
                 godot_warn!(
                     "set_map_for_rust: Invalid value type for key {:?} (expected Tile_Properties object): {:?}",
                     pos,
                     value.get_type() // Print the actual type received
                 );
                continue;
            };

            // Pass the Godot object reference to the parsing function
            if let Some(tile_properties) = Self::parse_and_initialize_tile_properties(&tile_object) {
                self.world_map.insert(pos, tile_properties);
            } else {
                godot_warn!(
                    "set_map_for_rust: Failed to parse tile object for key {:?}",
                    pos
                );
            }
        }
        godot_print!("Rust map set. {} tiles initialized.", self.world_map.len());
        if self.parameters.is_none() {
            godot_warn!("set_map_for_rust: Map set, but simulation parameters are missing!");
        }
    }

    #[func]
    fn get_map_from_rust(&self) -> Variant {
        let mut godot_dict = Dictionary::new();
        for (pos, tile_data) in &self.world_map {
            let minimal_tile_dict = self.serialize_minimal_tile_to_dict(tile_data);
            godot_dict.set(Variant::from(*pos), Variant::from(minimal_tile_dict));
        }
        Variant::from(godot_dict)
    }

    #[func]
    fn set_simulation_parameters(&mut self, params_variant: Variant) {
        let mut params = SimulationParameters::default();

        // Try parsing as Gd<RefCounted> first to access properties via get()
        if let Ok(obj) = Gd::<RefCounted>::try_from_variant(&params_variant) {
            params.width = obj.get("width").try_to::<i64>().unwrap_or(0) as i32;
            params.height = obj.get("height").try_to::<i64>().unwrap_or(0) as i32;
            params.scent_duration = obj.get("scent_duration").try_to::<i64>().unwrap_or(10) as i32;

            params.normaliser = obj.get("normaliser").try_to::<f64>().unwrap_or(200.0); // TODO: Make this configurable via parameters?
            params.max_genetic_distance = obj.get("max_genetic_distance").try_to::<f64>().unwrap_or(1.0);
            let min_dist = obj.get("min_allowed_genetic_distance").try_to::<f64>().unwrap_or(0.5);
            params.min_allowed_genetic_similarity =
                (1.0 - (min_dist / params.max_genetic_distance.max(0.01))).max(0.0);

            params.mutation_prob = obj.get("mutation_prob").try_to::<f64>().unwrap_or(0.05);
            params.mutation_half_range = obj.get("mutation_half_range").try_to::<f64>().unwrap_or(0.05);

            params.speed_cost = obj.get("speed_cost").try_to::<f64>().unwrap_or(0.0);
            params.mating_rate_cost = obj.get("mating_rate_cost").try_to::<f64>().unwrap_or(0.0);
            params.stealth_cost = obj.get("stealth_cost").try_to::<f64>().unwrap_or(0.0);
            params.detection_cost = obj.get("detection_cost").try_to::<f64>().unwrap_or(0.0);
        }
        // Fallback to parsing as Dictionary
        else if let Ok(dict) = Dictionary::try_from_variant(&params_variant) {
            params.width = dict
                .get("width")
                .and_then(|v| i64::try_from_variant(&v).ok())
                .unwrap_or(0) as i32;
            params.height = dict
                .get("height")
                .and_then(|v| i64::try_from_variant(&v).ok())
                .unwrap_or(0) as i32;
            params.scent_duration = dict
                .get("scent_duration")
                .and_then(|v| i64::try_from_variant(&v).ok())
                .unwrap_or(10) as i32;
            params.normaliser = dict
                .get("normaliser")
                .and_then(|v| f64::try_from_variant(&v).ok())
                .unwrap_or(11.0); // TODO: Make this configurable via parameters?

            godot_print!("Normaliser: {}", params.normaliser);  

            params.max_genetic_distance = dict
                .get("max_genetic_distance")
                .and_then(|v| f64::try_from_variant(&v).ok())
                .unwrap_or(1.0);
            let min_dist = dict
                .get("min_allowed_genetic_distance")
                .and_then(|v| f64::try_from_variant(&v).ok())
                .unwrap_or(0.5);
            params.min_allowed_genetic_similarity =
                (1.0 - (min_dist / params.max_genetic_distance.max(0.01))).max(0.0);
            params.mutation_prob = dict
                .get("mutation_prob")
                .and_then(|v| f64::try_from_variant(&v).ok())
                .unwrap_or(0.05);
            params.mutation_half_range = dict
                .get("mutation_half_range")
                .and_then(|v| f64::try_from_variant(&v).ok())
                .unwrap_or(0.05);

            params.speed_cost = dict
                .get("speed_cost")
                .and_then(|v| f64::try_from_variant(&v).ok())
                .unwrap_or(0.0);
            params.mating_rate_cost = dict
                .get("mating_rate_cost")
                .and_then(|v| f64::try_from_variant(&v).ok())
                .unwrap_or(0.0);
            params.stealth_cost = dict
                .get("stealth_cost")
                .and_then(|v| f64::try_from_variant(&v).ok())
                .unwrap_or(0.0);
            params.detection_cost = dict
                .get("detection_cost")
                .and_then(|v| f64::try_from_variant(&v).ok())
                .unwrap_or(0.0);
        } else {
            godot_error!(
                "set_simulation_parameters: Input is not a recognized Object or Dictionary."
            );
            return;
        }
        godot_print!("Rust simulation parameters set: {:?}", params);
        self.parameters = Some(params);
    }

    #[func]
    fn get_animal_statistics(&mut self) -> Variant {
        if self.animals.is_empty() {
            // Return default stats if no animals
            return Variant::from(self.serialize_stats_to_dict(&AnimalStatistics::default()));
        }

        let mut current_stats = self.stats.clone(); // Start with accumulated death/nutrition counts
                                                    // Reset fields calculated purely based on current snapshot
        current_stats.animal_count = 0;
        current_stats.speed_avg = 0.0;
        current_stats.speed_range = Vector2::new(f32::MAX, f32::MIN);
        current_stats.mating_rate_avg = 0.0;
        current_stats.mating_rate_range = Vector2::new(f32::MAX, f32::MIN);
        current_stats.food_preference_avg = 0.0;
        current_stats.food_preference_range = Vector2::new(f32::MAX, f32::MIN);
        current_stats.size_avg = 0.0;
        current_stats.size_range = Vector2::new(f32::MAX, f32::MIN);
        current_stats.stealth_avg = 0.0;
        current_stats.stealth_range = Vector2::new(f32::MAX, f32::MIN);
        current_stats.detection_avg = 0.0;
        current_stats.detection_range = Vector2::new(f32::MAX, f32::MIN);

        // Helper to update range
        fn update_range(range: &mut Vector2, value: f64) {
            let val_f32 = value as f32;
            range.x = range.x.min(val_f32);
            range.y = range.y.max(val_f32);
        }

        // Iterate and accumulate snapshot stats
        for animal in self.animals.values() {
            current_stats.animal_count += 1;
            current_stats.speed_avg += animal.genes.speed;
            update_range(&mut current_stats.speed_range, animal.genes.speed);
            current_stats.mating_rate_avg += animal.genes.mating_rate;
            update_range(
                &mut current_stats.mating_rate_range,
                animal.genes.mating_rate,
            );
            current_stats.food_preference_avg += animal.genes.food_preference;
            update_range(
                &mut current_stats.food_preference_range,
                animal.genes.food_preference,
            );
            current_stats.size_avg += animal.genes.size;
            update_range(&mut current_stats.size_range, animal.genes.size);
            current_stats.stealth_avg += animal.genes.stealth;
            update_range(&mut current_stats.stealth_range, animal.genes.stealth);
            current_stats.detection_avg += animal.genes.detection;
            update_range(&mut current_stats.detection_range, animal.genes.detection);
            current_stats.animal_nutrition_avg += animal.nutrition_norm;
            current_stats.animal_hydration_avg += animal.hydration_norm;
            current_stats.animal_ready_to_mate_avg += animal.ready_to_mate;
        }

        // Finalize averages
        let count_f64 = current_stats.animal_count as f64;
        if count_f64 > 0.0 {
            current_stats.speed_avg /= count_f64;
            current_stats.mating_rate_avg /= count_f64;
            current_stats.food_preference_avg /= count_f64;
            current_stats.size_avg /= count_f64;
            current_stats.stealth_avg /= count_f64;
            current_stats.detection_avg /= count_f64;
            current_stats.animal_nutrition_avg /= count_f64;
            current_stats.animal_hydration_avg /= count_f64;
            current_stats.animal_ready_to_mate_avg /= count_f64;
        }

        // Fix range vectors if no animals were processed
        if current_stats.animal_count == 0 {
            current_stats.speed_range = Vector2::ZERO;
            current_stats.mating_rate_range = Vector2::ZERO;
            current_stats.food_preference_range = Vector2::ZERO;
            current_stats.size_range = Vector2::ZERO;
            current_stats.stealth_range = Vector2::ZERO;
            current_stats.detection_range = Vector2::ZERO;
        }

        // Serialize the final stats (snapshot averages + accumulated counts)
        Variant::from(self.serialize_stats_to_dict(&current_stats))
    }

    #[func]
    fn spawn_predetermined_animals(&mut self, count: i64) {
        let Some(params) = &self.parameters else {
            godot_error!("Cannot spawn animals: Simulation parameters not set.");
            return;
        };
        if self.world_map.is_empty() {
            godot_error!("Cannot spawn animals: Map not set.");
            return;
        }
        godot_print!("Spawning {} predetermined animals...", count);
        let map_keys: Vec<Vector2i> = self.world_map.keys().cloned().collect();
        if map_keys.is_empty() {
            godot_error!("Cannot spawn animals: Map has no valid tile positions.");
            return;
        }

        for _ in 0..count {
            // <-- FIX: Import SliceRandom trait above to use choose
            let Some(pos) = map_keys.choose(&mut self.rng).copied() else {
                godot_warn!("Failed to pick random position (should not happen).");
                continue;
            };
            let animal_id = self.next_animal_id;
            self.next_animal_id += 1;

            // Use Animal's static method directly
            let animal = Animal::spawn_predetermined(animal_id, pos, params, &mut self.rng);

            if let Some(tile) = self.world_map.get_mut(&pos) {
                tile.animal_ids.push(animal_id);
                self.animals.insert(animal_id, animal);
            } else {
                godot_error!(
                    "Failed to find tile at {:?} for spawning animal {}",
                    pos,
                    animal_id
                );
                self.next_animal_id -= 1; // Reclaim ID
            }
        }
        godot_print!("Finished spawning. Total animals: {}", self.animals.len());
    }

    #[func]
    fn spawn_random_animals(&mut self, count: i64) {
        let Some(params) = &self.parameters else {
            godot_error!("Cannot spawn animals: Simulation parameters not set.");
            return;
        };
        if self.world_map.is_empty() {
            godot_error!("Cannot spawn animals: Map not set.");
            return;
        }
        godot_print!("Spawning {} random animals...", count);
        let map_keys: Vec<Vector2i> = self.world_map.keys().cloned().collect();
        if map_keys.is_empty() {
            godot_error!("Cannot spawn animals: Map has no valid tile positions.");
            return;
        }

        for _ in 0..count {
            // <-- FIX: Import SliceRandom trait above to use choose
            let Some(pos) = map_keys.choose(&mut self.rng).copied() else {
                godot_warn!("Failed to pick random position (should not happen).");
                continue;
            };
            let animal_id = self.next_animal_id;
            self.next_animal_id += 1;

            // Use Animal's static method directly
            let animal = Animal::spawn_random(animal_id, pos, params, &mut self.rng);

            if let Some(tile) = self.world_map.get_mut(&pos) {
                tile.animal_ids.push(animal_id);
                self.animals.insert(animal_id, animal);
            } else {
                godot_error!(
                    "Failed to find tile at {:?} for spawning animal {}",
                    pos,
                    animal_id
                );
                self.next_animal_id -= 1; // Reclaim ID
            }
        }
        godot_print!("Finished spawning. Total animals: {}", self.animals.len());
    }

    #[func]
    fn process_turn_for_all_animals(&mut self) {
        let Some(params) = &self.parameters else {
            godot_error!("Cannot process turn: Simulation parameters not set.");
            return;
        };
        if self.world_map.is_empty() {
            godot_error!("Cannot process turn: Map not set.");
            return;
        }
        let start_time = Instant::now();

        // --- Reset Turn Stats ---
        for animal in self.animals.values_mut() {
            animal.nutrition_gain_meat_this_turn = 0.0;
            animal.nutrition_gain_plant_this_turn = 0.0;
        }

        // --- Stage 1: Animal Decisions & Action Planning ---
        let animal_ids: Vec<i64> = self.animals.keys().cloned().collect();
        let mut actions: HashMap<i64, Action> = HashMap::with_capacity(animal_ids.len());
        let mut fight_requests: Vec<(i64, i64)> = Vec::new();
        let mut mate_requests: Vec<(i64, i64)> = Vec::new();

        for &animal_id in &animal_ids {
            if let Some(animal) = self.animals.get(&animal_id) {
                if animal.is_moving {
                    continue;
                } // Moving animals don't decide
                if let Some(tile) = self.world_map.get(&animal.map_position) {
                    // Pass immutable self.animals for read-only checks by decide_action
                    let action = animal.decide_action(tile, &self.animals, params, &mut self.rng);
                    actions.insert(animal_id, action);
                    match action {
                        Action::Hunt(defender_id) => fight_requests.push((animal_id, defender_id)),
                        Action::Mate(partner_id) => mate_requests.push((animal_id, partner_id)),
                        _ => {}
                    }
                } else {
                    godot_error!(
                        "Animal {} on non-existent tile {:?}",
                        animal_id,
                        animal.map_position
                    );
                }
            }
        }

        // --- Stage 2: Resolve Interactions (Fights, Mating) ---
        let mut births: Vec<Animal> = Vec::new();
        let mut deaths: Vec<i64> = Vec::new();
        let mut mated_this_turn: Vec<i64> = Vec::new();

        // Resolve Fights
        for (attacker_id, defender_id) in fight_requests {
            if deaths.contains(&attacker_id) || deaths.contains(&defender_id) {
                continue;
            }

            // TODO: unwrap should be safe, but this is not a very Rust solution
            let defender = self.animals.get(&defender_id).unwrap();
            let attacker = self.animals.get(&attacker_id).unwrap();

            let fight_result = attacker.fight(defender, &mut self.rng);

            match fight_result {
                Ok(true) => {
                    // Attacker won
                    if !deaths.contains(&defender_id) {
                        // Prevent double death entry
                        deaths.push(defender_id);
                        self.stats.animal_deaths_predation += 1;
                    }
                    // Overwrite attacker's action to EatMeat post-victory
                    actions.insert(attacker_id, Action::EatMeat);
                }
                Ok(false) => { /* Attacker lost or prey escaped, penalty applied in fight() */ }
                Err(_) => {
                    // Error in fight, e.g., invalid animal ID
                    godot_error!(
                        "Fight error between {} and {}: Invalid animal ID",
                        attacker_id,
                        defender_id
                    );
                }
            }
        }

        // Resolve Mating
        for (initiator_id, partner_id) in mate_requests {
            if deaths.contains(&initiator_id) || deaths.contains(&partner_id) {
                continue;
            }
            if mated_this_turn.contains(&initiator_id) || mated_this_turn.contains(&partner_id) {
                continue;
            }

            // Need immutable access to check readiness and compatibility
            let can_mate = if let (Some(initiator), Some(partner)) = (
                self.animals.get(&initiator_id),
                self.animals.get(&partner_id),
            ) {
                initiator.can_mate_with_animal(partner, params)
            } else {
                false
            };

            if can_mate {
                let initiator_pos;
                let initiator_gen;
                let initiator_genes;
                let partner_gen;
                let partner_genes;

                // Scope borrows to get necessary data
                {
                    let initiator = self.animals.get(&initiator_id).unwrap(); // Should exist
                    let partner = self.animals.get(&partner_id).unwrap(); // Should exist
                    initiator_pos = initiator.map_position;
                    initiator_gen = initiator.generation;
                    partner_gen = partner.generation;
                    // Clone genes for the child
                    initiator_genes = initiator.genes.clone();
                    partner_genes = partner.genes.clone();
                } // Borrows end here

                // Create child
                let child_id = self.next_animal_id;
                self.next_animal_id += 1;
                let child = Animal::spawn_new(
                    child_id,
                    initiator_pos,
                    initiator_gen.max(partner_gen) + 1,
                    &initiator_genes,
                    &partner_genes, // Use cloned genes
                    params,
                    &mut self.rng,
                );
                births.push(child);

                // Mark as mated and reset readiness (requires mutable access)
                mated_this_turn.push(initiator_id);
                mated_this_turn.push(partner_id);
                if let Some(a) = self.animals.get_mut(&initiator_id) {
                    a.ready_to_mate = 0.0;
                }
                if let Some(a) = self.animals.get_mut(&partner_id) {
                    a.ready_to_mate = 0.0;
                }

                // Mating overrides other planned actions
                actions.remove(&initiator_id);
                actions.remove(&partner_id);
            }
        }

        // --- Stage 3: Execute Actions (Non-Movement) & Update State ---
        for &animal_id in &animal_ids {
            if deaths.contains(&animal_id) || mated_this_turn.contains(&animal_id) {
                continue;
            }

            if let Some(animal) = self.animals.get_mut(&animal_id) {
                // Only execute planned action if animal is NOT currently moving
                if !animal.is_moving {
                    if let Some(action) = actions.get(&animal_id) {
                        if let Some(tile) = self.world_map.get_mut(&animal.map_position) {
                            match *action {
                                Action::EatMeat => {
                                    animal.eat_meat(tile);
                                }
                                Action::EatPlant => {
                                    animal.eat_plant_matter(tile);
                                }
                                Action::Drink => {
                                    animal.drink(tile);
                                }
                                Action::FollowScent(dest) => animal.begin_move_to_tile(dest),
                                Action::MoveRandom => animal.move_random(params, &mut self.rng),
                                Action::Hunt(_) => { /* Resolved earlier, potentially updated to EatMeat */
                                }
                                Action::Mate(_) => { /* Resolved earlier */ }
                            }
                        } else {
                            godot_error!(
                                "Tile {:?} not found for animal {} during action execution",
                                animal.map_position,
                                animal_id
                            );
                        }
                    }
                    // Else: No action planned (e.g., if Hunt/Mate failed without alternative) -> Animal does nothing this phase
                }

                // Update resources & check death conditions for ALL non-dead animals
                animal.update_animal_resources();
                if animal.animal_starved_of_resources() {
                    if !deaths.contains(&animal_id) {
                        deaths.push(animal_id);
                        if animal.nutrition <= 0.0 {
                            self.stats.animal_deaths_starvation += 1;
                        } else {
                            self.stats.animal_deaths_dehydration += 1;
                        }
                    }
                } else {
                    animal.age += 1;
                    if animal.age > animal.life_span {
                        if !deaths.contains(&animal_id) {
                            deaths.push(animal_id);
                            self.stats.animal_deaths_age += 1;
                        }
                    }
                }

                // Accumulate nutrition stats (using corrected field names)
                // <-- FIX: Use correct field name from AnimalStatistics struct
                //TODO:
                self.stats.nutrition_from_meat += animal.nutrition_gain_meat_this_turn;
                self.stats.nutrition_from_plants += animal.nutrition_gain_plant_this_turn;
            }
        }

        // --- Stage 3.5: Process Movement Tile Updates ---
        let animal_ids_for_move: Vec<i64> = self.animals.keys().cloned().collect();
        for &animal_id in &animal_ids_for_move {
            if deaths.contains(&animal_id) {
                continue;
            } // Skip dead animals

            let mut move_completed: Option<(Vector2i, Vector2i)> = None; // (prev_pos, new_pos)

            if let Some(animal) = self.animals.get_mut(&animal_id) {
                if animal.is_moving {
                    let prev_pos = animal.map_position; // Position *before* this tick
                    animal.moving_to_tile_turns_remaining -= 1;
                    if animal.moving_to_tile_turns_remaining <= 0 {
                        animal.is_moving = false;
                        animal.map_position = animal.destination; // Update position here
                        move_completed = Some((prev_pos, animal.destination));
                    }
                }
            }

            // Update map tiles outside the animal borrow
            if let Some((prev_pos, new_pos)) = move_completed {
                // Remove from old tile + add scent
                if let Some(tile) = self.world_map.get_mut(&prev_pos) {
                    tile.animal_ids.retain(|&id| id != animal_id);
                    tile.scent_trails.push(AnimalScent {
                        scent_direction: new_pos,
                        scent_duration_left: params.scent_duration,
                        animal_id,
                    });
                } else {
                    godot_warn!(
                        "Previous tile {:?} not found for moving animal {}",
                        prev_pos,
                        animal_id
                    );
                }

                // Add to new tile
                if let Some(tile) = self.world_map.get_mut(&new_pos) {
                    tile.animal_ids.push(animal_id);
                    let scent = AnimalScent {
                        scent_direction: prev_pos,
                        scent_duration_left: params.scent_duration,
                        animal_id,
                    };
                } else {
                    godot_error!(
                        "Destination tile {:?} not found for moving animal {}",
                        new_pos,
                        animal_id
                    );
                }
            }
        }

        // --- Stage 4: Apply Births and Deaths ---
        // Deaths (remove before births to handle edge case of dying same turn as born)
        for &dead_id in &deaths {
            // Iterate over collected death list
            if let Some(dead_animal) = self.animals.remove(&dead_id) {
                // Remove from map tile
                if let Some(tile) = self.world_map.get_mut(&dead_animal.map_position) {
                    tile.animal_ids.retain(|&id| id != dead_id);
                    let meat_amount = dead_animal.mass * 0.5;
                    add_meat_to_tile_piles(tile, meat_amount);
                } else {
                    godot_warn!(
                        "Tile {:?} not found for dead animal {}",
                        dead_animal.map_position,
                        dead_id
                    );
                }
            }
        }
        // Births
        for child in births {
            let child_id = child.animal_id;
            let child_pos = child.map_position;
            if let Some(tile) = self.world_map.get_mut(&child_pos) {
                tile.animal_ids.push(child_id);
                // Check if child died same turn? Unlikely with current flow but possible.
                if self.animals.contains_key(&child_id) {
                    godot_warn!("Duplicate animal ID {} generated for child!", child_id);
                    // Handle appropriately, maybe regenerate ID
                }
                self.animals.insert(child_id, child);
            } else {
                godot_warn!(
                    "Tile {:?} not found for newborn animal {}",
                    child_pos,
                    child_id
                );
                self.next_animal_id -= 1; // Reclaim ID if spawn failed to place on map
            }
        }

        // --- Stage 5: Update Map Tiles (Parallelized) ---
        self.world_map.par_iter_mut().for_each(|(_pos, tile)| {
            replenish_tile(tile, params);
        });

        // let duration = Instant::now() - start_time; 
    }

    #[func]
    fn replenish_map(&mut self) {
        let Some(params) = &self.parameters else {
            godot_error!("Cannot process turn: Simulation parameters not set.");
            return;
        };

        self.world_map.par_iter_mut().for_each(|(_pos, tile)| {
            replenish_tile(tile, params);
        });
    }
}

#[gdextension]
unsafe impl ExtensionLibrary for Simulation {}
