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

func construct_tile(tile : World.Tile_Properties, tile_index_ : Vector2i, tile_type_ : World.Tile_Type,
					curr_food_ : float, max_food_ : float, food_gain_ : float,
					movement_difficulty_ : float):
	tile.index = tile_index_
	tile.type = tile_type_
	tile.curr_food = curr_food_
	tile.max_food = max_food_
	tile.food_gain = food_gain_
	tile.movement_difficulty = movement_difficulty_

func set_cell_properties(pos : Vector2, type : World.Tile_Type,
						max : float, curr : float, gain : float,
						movement_difficulty : float):
	var tile = World.Tile_Properties.new()
	# result.construct_tile(pos, type, curr, max, gain, movement_difficulty)
	construct_tile(tile, pos, type, curr, max, gain, movement_difficulty)
	tiles[pos] = tile

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
		movement_difficulty = 2
	else:
		sprite_coords = Vector2i(0, 0)
		type = World.Tile_Type.PLAIN
		max = moist * temp * 15
		curr = randf_range(0, max)
		gain = moist * 3
		movement_difficulty = 1
	
	set_cell(0, pos, 0, sprite_coords)
	set_cell_properties(pos, type, max, curr, gain, movement_difficulty)

enum TEMPERATURE_TYPE {#selects the tile_set
	TUNDRA = 0,
	TAIGA = 1,
	TEMPERATE_LAND = 2,
	TROPICAL_LAND = 3,
	DESERT = 4,
}
enum MOISTURE_TYPE {#drives vegetation placement
	DRY,
	MODERATE,
	MOIST,
}

func get_type_from_temp(temp):
	# Step 1: Classify based on temperature
	var temp_type : TEMPERATURE_TYPE
	if temp < 0.1:
		temp_type = TEMPERATURE_TYPE.TUNDRA
	elif temp < 0.3:
		temp_type = TEMPERATURE_TYPE.TAIGA
	elif temp < 0.5:
		temp_type = TEMPERATURE_TYPE.TEMPERATE_LAND
	elif temp < 0.7:
		temp_type = TEMPERATURE_TYPE.TROPICAL_LAND
	else:
		temp_type = TEMPERATURE_TYPE.DESERT
	return temp_type

func get_type_from_moist(moist, temp_type : TEMPERATURE_TYPE):
	var moist_type : MOISTURE_TYPE
	match temp_type:
		TEMPERATURE_TYPE.TUNDRA:
			if moist < 0.4:
				moist_type = MOISTURE_TYPE.DRY
			elif moist < 0.7:
				moist_type = MOISTURE_TYPE.MODERATE
			else:
				moist_type = MOISTURE_TYPE.MOIST
		TEMPERATURE_TYPE.TAIGA:
			if moist < 0.3:
				moist_type = MOISTURE_TYPE.DRY
			elif moist < 0.7:
				moist_type = MOISTURE_TYPE.MODERATE
			else:
				moist_type = MOISTURE_TYPE.MOIST
		TEMPERATURE_TYPE.TEMPERATE_LAND:
			if moist < 0.2:
				moist_type = MOISTURE_TYPE.DRY
			elif moist < 0.7:
				moist_type = MOISTURE_TYPE.MODERATE
			else:
				moist_type = MOISTURE_TYPE.MOIST
		TEMPERATURE_TYPE.TROPICAL_LAND:
			if moist < 0.3:
				moist_type = MOISTURE_TYPE.DRY
			elif moist < 0.6:
				moist_type = MOISTURE_TYPE.MODERATE
			else:
				moist_type = MOISTURE_TYPE.MOIST
		TEMPERATURE_TYPE.DESERT:
			if moist < 0.6:
				moist_type = MOISTURE_TYPE.DRY
			elif moist < 0.9:
				moist_type = MOISTURE_TYPE.MODERATE
			else:
				moist_type = MOISTURE_TYPE.MOIST

func set_current_cell_new(pos, temp, moist):
	var temperature_type = get_type_from_temp(temp)
	var moisture_type = get_type_from_moist(moist)

	# Set the actual tile or representation for the biome
	set_cell(0, pos, temperature_type, Vector2i(0, 0))
	set_cell_properties(pos, type, max, curr, gain)#, movement_difficulty)
	# set_tile_at_position(pos, temperature_type, moisture_type)
