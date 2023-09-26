extends TileMap

var map_scene = load("res://SCENES/tile_map.tscn")
var Map : Tile_Map_Class = map_scene.instantiate()

var player_scene = load("res://SCENES/player.tscn")
var Player : CharacterBody2D = player_scene.instantiate()

var temperature = {}
var altitude = {}
var alt_seed = randi()
var moisture = {}
var moist_seed = randi()
var fast_noise = FastNoiseLite.new()

var day : int
var day_type : Day_Type
var hour : float

#World settings:
var hours_in_day : float = 20
var regrow_period : int = 7 # food regrows after x days
var velocity_start_point = 0.3
var resource_start_point = 0.3
var change_age_period_mult = 10 # how many days for an "average" animal to age
var corpse_timer = 50
var seek_hydration_threshold = 0.2
var seek_nutrition_threshold = 0.2
var animal_acceleration_mult = 10
var animal_velocity_mult = 5

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

var width = 35
var height = 35

var tile_size : Vector2 = Vector2(32, 32)
var tile_size_i : Vector2i = Vector2i(tile_size.x, tile_size.y)

var corpse_max_timer : float
var mutation_prob = 0.01

const Tile_Properties = preload("res://SCRIPTS/World_Generation/Tile_Properties.gd")

enum Day_Type {
	DAY,
	NIGHT,
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



