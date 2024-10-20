extends TileMap

var Map: Tile_Map_Class

var player_scene = load("res://SCENES/player.tscn")
var Player: CharacterBody2D = player_scene.instantiate()

# Simulation settings
var game_speed = 1
var phys_ticks_per_game_second = 5
var game_speed_controller = GameSpeedController.new()

# World variables
var temperature = {}
var altitude = {}
var moisture = {}
var fast_noise = FastNoiseLite.new()
# var world_seed = randi() % 100
var world_seed = 0

# NOTE: right now only serves to inform what the world average looks like
var temperature_avg: float = 0
var moisture_avg: float = 0
var herbivore_count: int = 0
var carnivore_count: int = 0
var game_time: float = 0

#World settings:
var food_regrow_timer : SimulationTimer

#time is used as real seconds
var food_regrow_time: float = 5000
var corpse_time: float = 200
var change_age_period_mult: float = 800

var food_crop_yield = 10
var reproduction_nutrition_cost = 0.4 # NOTE: usage is 0.4 * Animal.max_resources

var agility_modifier = 5

#Groups
var animal_group: String = "Animals"
var cadaver_group: String = "Cadavers"
var vegetation_group: String = "Vegetation"
var food_crop_group: String = "Food_Crop"
var food_regrow_group: String = "Food_Regrow"

#Scripts
var carnivore_script: String = "res://SCRIPTS/NPC_FSM/Carnivore.gd"
var herbivore_script: String = "res://SCRIPTS/NPC_FSM/Herbivore.gd"
var cadaver_script: String = "res://SCRIPTS/NPC_FSM/Cadaver.gd"

var width = 20
var height = 20

var tile_size: Vector2 = Vector2(32, 32)
var tile_size_i: Vector2i = Vector2i(tile_size.x, tile_size.y)

var edge_tiles = 1
var repulsion_margin = edge_tiles * tile_size.x # start repeling "edge_tiles" tiles from the edge
var max_repulsion_force = 1
var x_edge_from_center = width * tile_size.x
var y_edge_from_center = height * tile_size.y

var mutation_prob = 0.01

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

#NOTE : not used atm
enum Age_Group {
	JUVENILE = 0,
	ADOLESCENT = 1,
	ADULT = 2,
	OLD = 3,
}

func extract_gene(parent_1: float, parent_2: float) -> float: # only for float genes -> need new func for other types
	var mutation_prob = World.mutation_prob # global as of now
	var from_parent = randi_range(0, 1) # 0 -> parent_1 || 1 -> parent_2
	var mut = randf_range(0, 1)
	var result
	if from_parent:
		result = parent_2
	else:
		result = parent_1
	if mut < mutation_prob:
		var mut_val = randf_range(-0.05, 0.05) * result # if mutation occurs it can influence a gene by up to 5%.. also cant be a negative value
		result = min(1, max(0, result + mut_val))
	return result

func get_tile_pos(tile: Tile_Properties) -> Vector2:
	return Vector2(tile.index.x, tile.index.y) * tile_size + tile_size / 2

func _physics_process(delta):
	food_regrow_timer.do_timer(delta) # 
	game_time += delta

func _ready():
	var map_scene = load("res://SCENES/tile_map.tscn")
	Map = map_scene.instantiate()
