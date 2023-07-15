extends Node2D

@onready var tilemap = $TileMap
var width = 1024
var height = 1024

var temperature = {}
var altitude = {}
var moisture = {}
var biome = {}
var fast_noise = FastNoiseLite.new()

func generate_map(freq, oct):
	fast_noise.seed = randi()
	fast_noise.frequency = freq
	fast_noise.fractal_octaves = oct
	var grid_name = {}
	for x in width:
		for y in height:
			var rand = 2*(abs(fast_noise.get_noise_2d(x,y)))
			grid_name[Vector2(x, y)] = rand
	return grid_name

func _ready():
	temperature = generate_map(0.3, 0.5)
	moisture = generate_map(0.3, 0.5)
	altitude = generate_map(0.1, 0.5)
	set_tile(width, height)

func set_tile(width, height):
	for x in width:
		for y in height:
			var pos = Vector2(x, y)
			var alt = altitude[pos]
			var temp = temperature[pos]
			var moist = moisture[pos]

			#Ocean
			if between(alt, 0, 0.2):
				tilemap.set_cell(0, pos, 0, Vector2i(1, 2))
			#Beach
			elif between(alt, 0.2, 0.5):
				tilemap.set_cell(0, pos, 0, Vector2i(2, 3))
			else :
				if between(moist, 0.25, 0.4) and between(temp, 0.25, 0.6):
					tilemap.set_cell(0, pos, 0, Vector2i(3, 3))
				else:
					tilemap.set_cell(0, pos, 0, Vector2i(2, 0))

func between(val, start, end):
	if start <= val and val <= end:
		return true
	return false
