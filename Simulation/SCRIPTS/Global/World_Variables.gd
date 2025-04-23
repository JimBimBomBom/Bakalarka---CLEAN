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
    print("Godot simulation parameters: ", sim_params.width, sim_params.height)
    simulation.set_simulation_parameters(sim_params) # NOTE : Rust gets information about the simulation parameters
    simulation.set_map_for_rust(Map.tiles) # NOTE: Rust copies the initial map to its own data structure

    # simulation.spawn_predetermined_animals(spawn_animal_count) # NOTE: spawn animals in the world
    simulation.spawn_random_animals(spawn_animal_count) # NOTE: spawn animals in the world


# World variables
var temperature = {}
var altitude = {}
var moisture = {}
var fast_noise = FastNoiseLite.new()
var temperature_avg: float = 0
var moisture_avg: float = 0

var max_temperature_noise : float = 1
var max_moisture_noise : float = 1
var max_altitude_noise : float = 1

# NOTE: default simulation settings, can be changed in the GUI at startup
var run_simulation = true
var game_steps: int = 0
var data_collection_interval: int = 25
var simulation_speed: float # NOTE: number of steps per second
var world_initialized = false
var simulation_id: int = randi()
var spawn_animal_count: int = 0

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
var get_data_snapshot_period: float = 10 # NOTE: number of steps between data snapshots
var replenish_map_interval: int = 2

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

# TODO remove after Rust implementation all below

enum Vore_Type {
    CARNIVORE,
    HERBIVORE,
    OMNIVORE,
}

enum Age_Group {
    JUVENILE = 0,
    ADULT = 1,
    OLD = 2,
}

func between(val, start, end):
    if start <= val and val <= end:
        return true
    return false

func axial_distance_inline(a, b):
    return (abs(a.x - b.x) + abs(a.x + a.y - b.x - b.y) + abs(a.y - b.y)) / 2

func offset_to_axial(pos):
    var q = pos.x - (pos.y - (pos.y&1)) / 2
    var r = pos.y
    return Vector2i(q, r)

func axial_to_offset(pos):
    var x = pos.x + (pos.y - (pos.y&1)) / 2
    var y = pos.y
    return Vector2i(x, y)

func offset_distance(a, b):
    var ac = offset_to_axial(a)
    var bc = offset_to_axial(b)
    return axial_distance_inline(ac, bc)

func get_neighbouring_tiles_in_range(tile_pos : Vector2i, tile_range : int) -> Array[Vector2i]:
    var neighbours : Array[Vector2i] = []
    for x in range(-tile_range, tile_range + 1):
        for y in range(-tile_range, tile_range + 1):
            var pos = Vector2i(tile_pos.x + x, tile_pos.y + y)
            if between(pos.x, 0, sim_params.width - 1) and between(pos.y, 0, sim_params.height - 1) and offset_distance(tile_pos, pos) <= tile_range:
                neighbours.append(pos)
    neighbours.erase(tile_pos) # NOTE: remove the current tile from the list of neighbours
    return neighbours

func get_neighbouring_tiles(tile_pos: Vector2i):
    return get_neighbouring_tiles_in_range(tile_pos, 1)

func map(value, in_min, in_max, out_min, out_max):
    return (value - in_min) * ((out_max - out_min) / (in_max - in_min)) + out_min
