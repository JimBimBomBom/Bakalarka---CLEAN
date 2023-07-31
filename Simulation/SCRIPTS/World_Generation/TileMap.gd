extends TileMap

class_name Tile_Map_Class

enum Noise_Type {
	TEMP,
	ALT,
	MOIST,
	}

var tiles : Dictionary
	
# func _init():
# 	generate_world()

func generate_map(fast_noise, type, width, height, freq, oct, oct_gain):
	fast_noise.fractal_type = 3
	fast_noise.seed = randi()

	fast_noise.frequency = freq
	fast_noise.fractal_octaves = oct
	fast_noise.fractal_gain = oct_gain

	var grid_name = {}
	for x in range(-width, width + 1):
		for y in range(-height, height + 1):
			var rand = abs(fast_noise.get_noise_2d(x,y))
			grid_name[Vector2(x, y)] = rand
	return grid_name

# Called when the node enters the scene tree for the first time.
func generate_world():
	var fast_noise = World.fast_noise
	var width = World.width
	var height = World.height	
	World.temperature = generate_map(fast_noise, Noise_Type.TEMP, width, height, 0.0005, 10, 0.3)
	World.moisture = generate_map(fast_noise, Noise_Type.MOIST, width, height, 0.01, 5, 0.3)
	World.altitude = generate_map(fast_noise, Noise_Type.ALT, width, height, 0.005, 10, 0.3)
	set_tiles(width, height)

func set_tiles(width, height):
	for x in range(-width, width + 1):
		for y in range(-height, height + 1):
			var pos = Vector2(x, y)
			var alt = World.altitude[pos]
			var moist = World.moisture[pos]
			var temp = World.temperature[pos]
			set_current_cell(pos, alt, temp, moist)
			
func between(val, start, end):
	if start <= val and val <= end:
		return true
	return false

func set_cell_properties(pos : Vector2, type : World.Tile_Type,
						max : float, curr : float, gain : float,
						movement_difficulty : float):
	var result = World.Tile_Properties.new()
	result.construct_tile(pos, type, curr, max, gain, movement_difficulty)
	tiles[pos] = result

func set_current_cell(pos : Vector2, alt, temp, moist):
	var sprite_coords = Vector2i(0, 0)
	var type : World.Tile_Type
	var max : float
	var curr : float
	var gain : float
	var movement_difficulty : float
	if moist < 0.07:
		sprite_coords = Vector2i(2, 2)
		type = World.Tile_Type.WATER
		max = 0
		curr = 0
		gain = 0
		movement_difficulty = 0.7
	else:
		sprite_coords = Vector2i(0, 0)
		type = World.Tile_Type.PLAIN
		max = moist * temp * 15
		curr = randf_range(0, max)
		gain = moist * 3
		movement_difficulty = 0
	
	set_cell(0, pos, 0, sprite_coords)
	set_cell_properties(pos, type, max, curr, gain, movement_difficulty)
