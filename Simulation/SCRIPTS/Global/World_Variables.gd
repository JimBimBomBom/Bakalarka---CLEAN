extends TileMap

var map_scene = load("res://SCENES/tile_map_layer.tscn")
var camera_scene = load("res://SCENES/camera.tscn")
var ui_statistics_scene = load("res://SCENES/UI_statistics.tscn")
var Map: Tile_Map_Class = map_scene.instantiate()
var Camera: Camera2D = camera_scene.instantiate()
var UI_Statistics: CanvasLayer = ui_statistics_scene.instantiate()


# Simulation settings
var game_speed_controller = GameSpeedController.new()

# World variables
var temperature = {}
var altitude = {}
var moisture = {}
var fast_noise = FastNoiseLite.new()
var temperature_avg: float = 0
var moisture_avg: float = 0

var water_level_altitude = 0

# NOTE: default simulation settings, can be changed in the GUI at startup
var game_steps: float = 0
var simulation_id: int = randi()

var game_speed = 1
var world_seed = 1225
var width: int = 50
var height: int = 70

var spawn_animal_count: int = 100

#Map settings
var tile_size_i: Vector2i = Vector2i(32, 32) # NOTE: gets set in world -> this is just initialization
var zero_pos = Vector2i(0, 0)
var x_margin_for_statistics = 0.2 # NOTE: 20% of the screen width
var padding_margin = 0.1 # NOTE: 10% of the screen width/height

#World settings:
var food_regrow_timer : SimulationTimer
var get_data_snapshot_timer : SimulationTimer
var get_data_snapshot_period: float = 10 # NOTE: number of steps between data snapshots

#timers -> TODO
var food_regrow_time: float = 2000
var corpse_time: float = 1500
var change_age_period_mult: float = 2000

var reproduction_energy_cost = 0.4 # NOTE: usage is 0.4 * Animal.max_energy.. could be based on an animals characteristics.

var agility_modifier = 5

#Mutation settings
var mutation_prob = 0.01
var mutation_half_range = 0.05

const Tile_Properties = preload("res://SCRIPTS/World_Generation/Tile_Properties.gd")
const Animal = preload("res://SCRIPTS/NPC_FSM/Animal.gd")

enum Vore_Type {
    CARNIVORE,
    HERBIVORE,
    OMNIVORE,
}

# Whittaker biome system
enum Biome_Type {
    Tundra,
    Taiga,
    Temperate_Rainforest,
    Tropical_Rainforest,
    Temperate_Forest,
    Savanna,
    Grassland,
    Desert,
    Water,
}
enum Age_Group {
    JUVENILE = 0,
    ADOLESCENT = 1,
    ADULT = 2,
    OLD = 3,
}

# func get_tile_pos(tile: Tile_Properties) -> Vector2:
#     return Vector2(tile.index.x, tile.index.y) * tile_size + tile_size / 2
