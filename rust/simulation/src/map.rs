use crate::structs::*;

// Function to update tile state per turn (plants, hydration, spoilage, scents)
pub fn replenish_tile(tile: &mut RustTileProperties, params: &SimulationParameters) {
    // Replenish plants
    tile.plant_matter = (tile.plant_matter + 1.0*tile.plant_matter_gain).min(tile.max_plant_matter);

    // Replenish hydration
    tile.hydration = tile.max_hydration; 

    // Iterate and remove expired, then sum.
    let mut meat_sum = 0.0;
    tile.meat_in_rounds.retain_mut(|meat| {
        //  meat.spoils_in -= 1;
         meat.spoils_in -= 5;
         if meat.spoils_in > 0 {
             meat_sum += meat.amount;
             true // Keep
         } else {
             false // Discard
         }
    });
    tile.total_meat = meat_sum;

    // Age scents
    tile.scent_trails.retain_mut(|scent| {
        scent.scent_duration_left -= 5;
        // scent.scent_duration_left -= 1;
        scent.scent_duration_left > 0 // Keep if duration > 0
    });
}

 // Helper to convert Rust BiomeType to Godot integer if needed 
pub fn biome_to_int(biome: BiomeType) -> i32 {
    match biome {
        BiomeType::Uninitialized => -1,
        BiomeType::TropicalRainforest => 0,
        BiomeType::Savanna => 1,
        BiomeType::Desert => 2,
        BiomeType::TemperateRainforest => 3,
        BiomeType::TemperateForest => 4,
        BiomeType::Grassland => 5,
        BiomeType::Taiga => 6,
        BiomeType::Tundra => 7,
        BiomeType::Water => 8,
    }
}
// Helper to convert int back to BiomeType
pub fn int_to_biome(value: i32) -> BiomeType {
    match value {
         0 => BiomeType::TropicalRainforest,
         1 => BiomeType::Savanna,
         2 => BiomeType::Desert,
         3 => BiomeType::TemperateRainforest,
         4 => BiomeType::TemperateForest,
         5 => BiomeType::Grassland,
         6 => BiomeType::Taiga,
         7 => BiomeType::Tundra,
         8 => BiomeType::Water,
         _ => BiomeType::Uninitialized, // Default or error case
    }
}

// Adds meat, creating/merging piles based on spoil rate matching *last* element
pub fn add_meat_to_tile_piles(tile: &mut RustTileProperties, amount: f64) {
    if amount <= 0.0 { return; }
    tile.total_meat += amount;

    let spoil_turns = (tile.temperature * 9.0 + tile.moisture * 7.0) as i32;
    if let Some(last_meat) = tile.meat_in_rounds.last_mut() {
        // GD used !=, implying merge only if exact match
        if last_meat.spoils_in == spoil_turns {
            last_meat.amount += amount;
            return; // Added to existing last pile
        }
    }
    // Add new pile if no piles exist or last pile has different spoil rate
    tile.meat_in_rounds.push(Meat { amount, spoils_in: spoil_turns }); // Add to end
}

// Removes meat from piles, oldest first. Returns amount actually removed.
pub fn remove_meat_from_tile_piles(tile: &mut RustTileProperties, mut amount_to_remove: f64) -> f64 {
    let initial_request = amount_to_remove;
    let mut actual_removed = 0.0;

     // Use VecDeque if frequent front removal is needed, otherwise Vec remove(0) is O(N)
     // Assuming meat_in_rounds is Vec, sorted oldest first (inserted at front in GD?)
     // Let's adjust GD logic: add meat to end, remove from front (index 0) for FIFO spoilage.

    while tile.meat_in_rounds.len() != 0 && amount_to_remove > 0.0 {
        let meat_pile = &mut tile.meat_in_rounds[0]; // Mutable borrow pile 0
        let can_take = meat_pile.amount.min(amount_to_remove);

        amount_to_remove -= can_take; // Partial consumption
        actual_removed += can_take;
        if can_take >= meat_pile.amount {
            tile.meat_in_rounds.remove(0);
            continue; // Move to next pile
        }
        else {
            break; // Partial consumption -> reduced meat amount in pile, exit loop
        }
    }

    actual_removed
}