extends Node

var map_scene = load("res://SCENES/tile_map_layer.tscn")
var Map: Tile_Map_Class = map_scene.instantiate()
var camera_scene = load("res://SCENES/camera.tscn")
var Camera: Camera2D = camera_scene.instantiate()
var ui_statistics_scene = load("res://SCENES/UI_statistics.tscn")
var UI_Statistics: CanvasLayer = ui_statistics_scene.instantiate()

var simulation_parameters_file = ""
var simulation # NOTE: is initialized when creating a simulation in Rust

var sim_params = Simulation_Parameters.new()

func _ready():
    add_child(World.Map)

    # var unit_tests_scene = load("res://SCENES/unit_tests.tscn")
    # var Unit_Tests : Node = unit_tests_scene.instantiate() 
    # Unit_Tests.run_tests()

func create_rust_simulation():
    simulation = Simulation.new()
    simulation.set_simulation_parameters(sim_params) # NOTE : Rust gets information about the simulation parameters
    simulation.set_map_for_rust(Map.tiles) # NOTE: Rust copies the initial map to its own data structure

    # simulation.spawn_predetermined_animals(spawn_animal_count) # NOTE: spawn animals in the world
    simulation.spawn_random_animals(sim_params.spawn_animal_count) # NOTE: spawn animals in the world


# World variables
var temperature = {}
var altitude = {}
var moisture = {}
var fast_noise = FastNoiseLite.new()
var temperature_avg: float = 0
var moisture_avg: float = 0

# NOTE: default simulation settings, can be changed in the GUI at startup
var run_simulation = true
var game_steps: int = 0
var data_collection_interval: int = 25
var simulation_speed: float # NOTE: number of steps per second
var world_initialized = false
var simulation_id: int = randi()

#Statistics
var animal_deaths_starvation: int = 0
var animal_deaths_dehydration: int = 0
var animal_deaths_age: int = 0
var animal_deaths_predation: int = 0

var nutrition_from_meat: float = 0
var nutrition_from_plants: float = 0

var generate_graphs: int = 1

#Map settings
var tile_size_i: Vector2i = Vector2i(32, 32) # NOTE: gets set in world -> this is just initialization
var zero_pos = Vector2i(0, 0)
var x_margin_for_statistics = 0.2 # NOTE: 20% of the screen width
var padding_margin = 0.1 # NOTE: 10% of the screen width/height

#World settings:

var world_seed : int

# Whittaker biome system
enum Biome_Type {
    Uninitialized,
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

func map(value, in_min, in_max, out_min, out_max):
    return (value - in_min) * ((out_max - out_min) / (in_max - in_min)) + out_min
