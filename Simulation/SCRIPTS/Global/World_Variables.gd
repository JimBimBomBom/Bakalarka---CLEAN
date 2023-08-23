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
#var biome = {}
var fast_noise = FastNoiseLite.new()

var day : int
var day_type : Day_Type
var hour : float
var hours_in_day : float

var animal_group : String = "Animals"
var cadaver_group : String = "Cadavers"
var vegetation_group : String = "Vegetation"

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
	BARREN_PLAIN,
	MOUNTAIN,
}

func get_tile_pos(tile : Tile_Properties) -> Vector2:
	return Vector2(tile.index.x, tile.index.y)*tile_size + tile_size/2

func change_tile_type(tile : Tile_Properties, new_type : Tile_Type):
	tile.type = new_type

