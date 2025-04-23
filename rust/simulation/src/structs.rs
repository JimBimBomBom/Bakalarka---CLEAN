// src/structs.rs
use std::collections::HashMap;

use godot::builtin::Vector2i;
use godot::builtin::Vector2;

// --- Parameters ---
#[derive(Debug, Clone, Default)]
pub struct SimulationParameters {
    pub width: i32,
    pub height: i32,
    pub max_genetic_distance: f64,
    pub min_allowed_genetic_similarity: f64, // Renamed for clarity based on usage
    pub mutation_prob: f64,
    pub mutation_half_range: f64,
    pub scent_duration: i32,
    // Add any other global parameters needed from 'World'
    pub normaliser: f64, // From Animal_Characteristics
}

// --- Statistics ---
#[derive(Debug, Clone, Default)]
pub struct AnimalStatistics {
    pub animal_count: i64,
    pub speed_avg: f64,
    pub speed_range: Vector2, // (min, max)
    pub mating_rate_avg: f64,
    pub mating_rate_range: Vector2,
    pub food_preference_avg: f64,
    pub food_preference_range: Vector2,
    pub size_avg: f64,
    pub size_range: Vector2,
    pub stealth_avg: f64,
    pub stealth_range: Vector2,
    pub detection_avg: f64,
    pub detection_range: Vector2,
    pub animal_nutrition_avg: f64, // Renamed from _label
    pub animal_hydration_avg: f64,
    pub animal_ready_to_mate_avg: f64, // Renamed from _love_label
    pub animal_deaths_age: i64,
    pub animal_deaths_starvation: i64,
    pub animal_deaths_dehydration: i64,
    pub animal_deaths_predation: i64,
    pub nutrition_from_meat: f64,
    pub nutrition_from_plants: f64,
}

// --- Genes ---
#[derive(Debug, Clone, Default)]
pub struct AnimalGenes {
    pub size: f64,
    pub speed: f64,
    pub food_preference: f64, 
    pub mating_rate: f64,
    pub stealth: f64,
    pub detection: f64,
}

// --- Map ---
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum BiomeType {
    Uninitialized, // Should not persist after generation
    TropicalRainforest,
    Savanna,
    Desert,
    TemperateRainforest,
    TemperateForest,
    Grassland,
    Taiga,
    Tundra,
    Water, // Added based on set_current_cell usage
}

#[derive(Debug, Clone)]
pub struct Meat {
    pub amount: f64,
    pub spoils_in: i32, // Assuming discrete turns
}

#[derive(Debug, Clone)]
pub struct AnimalScent {
    pub scent_direction: Vector2i, // Tile animal came FROM
    pub scent_duration_left: i32,
    pub animal_id: i64,
}

#[derive(Debug, Clone)]
pub struct RustTileProperties {
    // No index needed if stored in HashMap with Vector2i key
    pub biome: BiomeType,
    pub animal_ids: Vec<i64>,
    pub scent_trails: Vec<AnimalScent>,
    pub temperature: f64,
    pub moisture: f64,
    pub plant_matter: f64,
    pub plant_matter_gain: f64,
    pub max_plant_matter: f64,
    pub meat_in_rounds: Vec<Meat>,
    pub total_meat: f64,
    pub meat_spoil_rate: f64, // Consider turns instead? GDScript uses 1/(temp*7)
    pub hydration: f64,
    pub max_hydration: f64,
    // Add altitude if needed by logic later
}

pub type WorldMap = HashMap<Vector2i, RustTileProperties>;

// --- Animal ---
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum VoreType {
    Carnivore,
    Herbivore,
    Omnivore,
}

#[derive(Debug, Clone)]
pub struct Animal {
    // IDs and Position
    pub animal_id: i64,
    pub map_position: Vector2i,

    // State
    pub genes: AnimalGenes,
    pub vore_type: VoreType,
    pub generation: i32,
    pub age: i32,
    pub is_moving: bool,
    pub moving_to_tile_turns_remaining: i32,
    pub destination: Vector2i,

    // Characteristics / Resources (incorporating Animal_Characteristics)
    pub mass: f64,
    pub food_consumption: f64,
    pub water_consumption: f64,
    pub ready_to_mate: f64, // 0.0 to 1.0
    pub life_span: i32,
    pub turns_to_change_tile: i32,
    pub max_resources: f64,
    pub nutrition: f64,
    pub nutrition_norm: f64,
    pub seek_nutrition_norm: f64, // Could be parameter or gene-based
    pub hydration: f64,
    pub hydration_norm: f64,
    pub seek_hydration_norm: f64, // Could be parameter or gene-based

    pub nutrition_gain_plant_this_turn: f64,
    pub nutrition_gain_meat_this_turn: f64,
}
