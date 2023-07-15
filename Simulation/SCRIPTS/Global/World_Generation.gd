extends TileMap

var temperature = {}

var altitude = {}
var alt_seed = randi()
var moisture = {}
var moist_seed = randi()
#var biome = {}
var fast_noise = FastNoiseLite.new()

@export var width = 100
@export var height = 100

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

