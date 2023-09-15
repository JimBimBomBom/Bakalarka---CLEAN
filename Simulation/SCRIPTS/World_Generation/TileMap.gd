extends TileMap

class_name Tile_Map_Class

enum Noise_Type {
	TEMP,
	ALT,
	MOIST,
	}

var tiles = {}

func generate_map(fast_noise, width, height, freq, oct, oct_gain):
	fast_noise.fractal_type = 3
	fast_noise.seed = randi()

	fast_noise.frequency = freq
	fast_noise.fractal_octaves = oct
	fast_noise.fractal_gain = oct_gain

	var grid_name = {}
	for x in range(-width, width + 1):
		for y in range(-height, height + 1):
			var noise = abs(fast_noise.get_noise_2d(x,y))
			grid_name[Vector2i(x, y)] = noise
	return grid_name

func generate_world():
	var fast_noise = World.fast_noise
	var width = World.width
	var height = World.height	
	World.temperature = generate_map(fast_noise, width, height, 0.0005, 10, 0.3)
	World.moisture = generate_map(fast_noise, width, height, 0.01, 5, 0.3)
	World.altitude = generate_map(fast_noise, width, height, 0.005, 10, 0.3)
	set_tiles(width, height)
			
func set_tiles(width, height):
	for x in range(-width, width + 1):
		for y in range(-height, height + 1):
			var pos = Vector2i(x, y)
			var alt = World.altitude[pos]
			var moist = World.moisture[pos]
			var temp = World.temperature[pos]
			set_current_cell(pos, alt, temp, moist)

func get_type_from_temp(temp):
	var temp_type : World.Temperature_Type
	if temp < 0.3:
		temp_type = World.Temperature_Type.TAIGA
	elif temp < 0.7:
		temp_type = World.Temperature_Type.TEMPERATE_LAND
	else:
		temp_type = World.Temperature_Type.TROPICAL_LAND
	return temp_type

func set_tile_properties(tile : World.Tile_Properties, curr_food_ : float, max_food_ : float, 
						 food_gain_ : float, tile_biome : World.Temperature_Type, tile_type : World.Tile_Type, 
						 pos : Vector2i):
	tile.curr_food = curr_food_
	tile.max_food = max_food_
	tile.food_gain = food_gain_
	tile.biome = tile_biome
	tile.type = tile_type
	tile.index = pos

func create_tile_properties(pos : Vector2i, temp, moist, tile_biome, tile_type):
	var tile = World.Tile_Properties.new() 
	var max = moist * temp * 5
	var gain = temp * 3
	var curr = randf_range(0, gain)
	set_tile_properties(tile, curr, max, gain, tile_biome, tile_type, pos)
	tiles[pos] = tile

func set_current_cell(pos, alt, temp, moist):
	var temperature_type = get_type_from_temp(temp)
	if alt < 0.2 and moist > 0.9:
		set_cell(0, pos, 0, Vector2i(2, 2)) 	# temp_type defines the ID of our Tile_Set,
		create_tile_properties(pos, 0, 0, temperature_type, World.Tile_Type.WATER)
	else:
		# var temperature_type = get_type_from_temp(temp)
		set_cell(0, pos, temperature_type, Vector2i(0, 0)) 	# temp_type defines the ID of our Tile_Set,
															# where the basic tile is always (0, 0)
		create_tile_properties(pos, temp, moist, temperature_type, World.Tile_Type.PLAIN)
