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
var hours_in_day : float

#Groups
var animal_group : String = "Animals"
var cadaver_group : String = "Cadavers"
var vegetation_group : String = "Vegetation"

#Scripts
var carnivore_script : String = "res://SCRIPTS/NPC_FSM/Carnivore.gd"
var herbivore_script : String = "res://SCRIPTS/NPC_FSM/Herbivore.gd"

var width = 50
var height = 50

var tile_size : Vector2 = Vector2(32, 32)
var tile_size_i : Vector2i = Vector2i(tile_size.x, tile_size.y)

var corpse_max_timer : float

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

func get_tile_pos(tile : Tile_Properties) -> Vector2:
	return Vector2(tile.index.x, tile.index.y)*tile_size + tile_size/2

