extends TileMap

var Map: Tile_Map_Class

var player_scene = load("res://SCENES/player.tscn")
var Player: CharacterBody2D = player_scene.instantiate()

# Simulation settings
var phys_ticks_per_game_second = 5
var game_speed_controller = GameSpeedController.new()

# World variables
var temperature = {}
var altitude = {}
var moisture = {}
var fast_noise = FastNoiseLite.new()
var temperature_avg: float = 0
var moisture_avg: float = 0

# NOTE: default simulation settings, can be changed in the GUI at startup
var game_speed = 1
var world_seed = 0
var herbivore_count: int = 0
var carnivore_count: int = 0
var width = 20
var height = 20

var game_time: float = 0

#World settings:
var food_regrow_timer : SimulationTimer

#time is used as real seconds
var food_regrow_time: float = 5000
var corpse_time: float = 2000
var change_age_period_mult: float = 8000

var food_crop_yield = 20
var reproduction_nutrition_cost = 0.4 # NOTE: usage is 0.4 * Animal.max_resources

var agility_modifier = 5

#Mutation settings
var mutation_prob = 0.01
var mutation_half_range = 0.05

#Scripts
var carnivore_script: String = "res://SCRIPTS/NPC_FSM/Carnivore.gd"
var herbivore_script: String = "res://SCRIPTS/NPC_FSM/Herbivore.gd"

var tile_size: Vector2 = Vector2(32, 32)
var tile_size_i: Vector2i = Vector2i(tile_size.x, tile_size.y)

var x_edge_from_center = width * tile_size.x
var y_edge_from_center = height * tile_size.y

const Tile_Properties = preload("res://SCRIPTS/World_Generation/Tile_Properties.gd")

enum Vore_Type {
    CARNIVORE,
    HERBIVORE,
    OMNIVORE,
}
enum Vegetation_Type {
    TREE_1,
    TREE_2,
    BUSH_1,
    BUSH_2,
}
enum Tile_Type {
    WATER,
    PLAIN,
    MOUNTAIN,
}
enum Temperature_Type { # selects the tile_set
    TUNDRA = 0,
    TAIGA = 1,
    TEMPERATE_LAND = 2,
    TROPICAL_LAND = 3,
    DESERT = 4,
}

enum Age_Group {
    JUVENILE = 0,
    ADOLESCENT = 1,
    ADULT = 2,
    OLD = 3,
}

func get_tile_pos(tile: Tile_Properties) -> Vector2:
    return Vector2(tile.index.x, tile.index.y) * tile_size + tile_size / 2
