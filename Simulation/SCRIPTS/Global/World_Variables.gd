extends TileMap

#TODO list:
# add energy cost to reproduction
# fix water spawning -> too rare atm, and all water regions are very small 

var Map

var player_scene = load("res://SCENES/player.tscn")
var Player : CharacterBody2D = player_scene.instantiate()

var temperature = {}
var altitude = {}
var alt_seed = randi()
var moisture = {}
var moist_seed = randi()
var fast_noise = FastNoiseLite.new()

var hour : float
var day : int
var week : int
var season : Season_Type 

var temperature_avg : float = 0
var moisture_avg : float = 0

var moisture_change_magnitude = 0.1

var temp_correction_magnitude = 0.2
var target_avg_temp : float = 0.5
var avg_temp_interval: float = 0.5
var season_ranges = {
	Season_Type.SPRING: Vector2(-0.05, 0.15),
	Season_Type.SUMMER: Vector2(-0.08, 0.12),
	Season_Type.AUTUMN: Vector2(-0.15, 0.5),
	Season_Type.WINTER: Vector2(-0.12, 0.8),
}

#World settings:
var hours_in_day : float = 2
var days_in_week : int = 1
var weeks_in_season : int = 4

var velocity_start_point = 0.3
var resource_start_point = 0.3
var change_age_period_mult = 10 # how many days for an "average" animal to age
var corpse_timer = 50
var seek_hydration_threshold = 0.2
var seek_nutrition_threshold = 0.2

var animal_acceleration_mult = 10
var animal_velocity_mult = 5
var base_resource_use = 2
var energy_per_resource_gain = 2

var fight_back_chance = 0.2
var agility_modifier = 5

#Groups
var animal_group : String = "Animals"
var cadaver_group : String = "Cadavers"
var vegetation_group : String = "Vegetation"
var food_crop_group : String = "Food_Crop"
var food_regrow_group : String = "Food_Regrow"

#Scripts
var carnivore_script : String = "res://SCRIPTS/NPC_FSM/Carnivore.gd"
var herbivore_script : String = "res://SCRIPTS/NPC_FSM/Herbivore.gd"

var width = 100
var height = 100

var tile_size : Vector2 = Vector2(32, 32)
var tile_size_i : Vector2i = Vector2i(tile_size.x, tile_size.y)

var edge_tiles = 3
var repulsion_margin = edge_tiles*tile_size.x # start repeling "edge_tiles" tiles from the edge
var max_repulsion_force = 1
var x_edge_from_center = width * tile_size.x
var y_edge_from_center = height * tile_size.y

var corpse_max_timer : float
var mutation_prob = 0.01

const Tile_Properties = preload("res://SCRIPTS/World_Generation/Tile_Properties.gd")

enum Season_Type {
	SPRING,
	SUMMER,
	AUTUMN,
	WINTER,
}
enum Weather_Type {
	CLEAR,
	CLOUDY,
	RAIN,
	STORM, #only an idea atm
}

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
enum Temperature_Type {#selects the tile_set
	TUNDRA = 0,
	TAIGA = 1,
	TEMPERATE_LAND = 2,
	TROPICAL_LAND = 3,
	DESERT = 4,
}
enum Gender {
	MALE,
	FEMALE,
}
enum Age_Group {
	JUVENILE,
	ADULT,
	OLD,
}

func extract_gene(parent_1 : float, parent_2 : float) -> float: # only for float genes -> need new func for other types
	var mutation_prob = World.mutation_prob#global as of now
	var from_parent = randi_range(0, 1)#0 -> parent_1 || 1 -> parent_2
	var mut = randf_range(0, 1)
	var result
	if from_parent:
		result = parent_2
	else:
		result = parent_1
	if mut < mutation_prob:
		var mut_val = randf_range(-0.05, 0.05)*result#if mutation occurs it can influence a gene by up to 5%.. also cant be a negative value
		result = min(1, max(0, result + mut_val))
	return result

func get_tile_pos(tile : Tile_Properties) -> Vector2:
	return Vector2(tile.index.x, tile.index.y)*tile_size + tile_size/2

func _ready():
	var map_scene = load("res://SCENES/tile_map.tscn")
	Map = map_scene.instantiate()
