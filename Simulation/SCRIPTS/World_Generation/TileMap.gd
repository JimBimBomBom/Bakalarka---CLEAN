extends TileMap

class_name Tile_Map_Class

enum Noise_Type {
	TEMP,
	ALT,
	MOIST,
}

var tiles = {}

func generate_map(fast_noise, freq, oct, oct_gain):
	fast_noise.fractal_type = 3
	fast_noise.seed = randi()

	fast_noise.frequency = freq
	fast_noise.fractal_octaves = oct
	fast_noise.fractal_gain = oct_gain

	var grid_name = {}
	for x in range(-World.width, World.width + 1):
		for y in range(-World.height, World.height + 1):
			var noise = abs(fast_noise.get_noise_2d(x,y))
			grid_name[Vector2i(x, y)] = noise
	return grid_name

func generate_world():
	World.temperature = generate_map(World.fast_noise, 0.005, 10, 0.3)
	World.moisture = generate_map(World.fast_noise, 0.01, 5, 0.3)
	World.altitude = generate_map(World.fast_noise, 0.005, 10, 0.3)
	set_tiles()
			
func set_tiles():
	for x in range(-World.width, World.width + 1):
		for y in range(-World.height, World.height + 1):
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

func create_tile_properties(pos : Vector2i, temp, moist, tile_biome, tile_type):
	var tile = World.Tile_Properties.new() 
	tile.type = tile_type
	tile.occupied = false
	tile.biome = tile_biome
	tile.index = pos
	tiles[pos] = tile

func set_current_cell(pos, alt, temp, moist):
	var temperature_type = get_type_from_temp(temp)
	if alt < 0.1:
		set_cell(0, pos, 0, Vector2i(2, 2)) 	# temp_type defines the ID of our Tile_Set,
		create_tile_properties(pos, 0, 0, temperature_type, World.Tile_Type.WATER)
	else:
		set_cell(0, pos, temperature_type, Vector2i(0, 0)) 	# temp_type defines the ID of our Tile_Set,
		create_tile_properties(pos, temp, moist, temperature_type, World.Tile_Type.PLAIN)

func update_map():
	var temp_change = generate_map(World.fast_noise, 0.005, 4, 0.3)
	var moist_change = generate_map(World.fast_noise, 0.005, 1, 0.3)

	var temp_correction_factor = get_balancing_factor()
	for x in range(-World.width, World.width + 1):
		for y in range(-World.height, World.height + 1):
			var seasonal_variation = temp_change[Vector2i(x, y)]
			seasonal_variation = adjust_for_season(seasonal_variation)
			World.temperature[Vector2i(x, y)] += seasonal_variation + temp_correction_factor * abs(seasonal_variation)
			World.temperature[Vector2i(x, y)] = clamp(World.temperature[Vector2i(x, y)], 0.0, 1.0)

			var weekly_variation = moist_change[Vector2i(x, y)]
			weekly_variation = map(weekly_variation, 0, 1, -0.2, 0.2)
			World.moisture[Vector2i(x, y)] += weekly_variation
			World.moisture[Vector2i(x, y)] = clamp(World.moisture[Vector2i(x, y)], 0.0, 1.0)

	set_tiles()

	World.temperature_avg = calculate_average_2d_array(World.temperature)
	World.moisture_avg = calculate_average_2d_array(World.moisture)

func calculate_average_2d_array(dict: Dictionary) -> float:
	var sum : float = 0
	var count = 0
	for item in dict.values():
		sum += item
		count += 1
	
	if count > 0:
		return sum / count
	else:
		return 0

func get_balancing_factor() -> float:
	var correction_factor = 0
	var current_avg_temp = World.temperature_avg
	var target_avg_temp = World.target_avg_temp
	var lower_bound = target_avg_temp - World.avg_temp_interval
	var upper_bound = target_avg_temp + World.avg_temp_interval

	if current_avg_temp < lower_bound:
		correction_factor = World.temp_correction_magnitude * max(0, (current_avg_temp - target_avg_temp) / target_avg_temp)
	if current_avg_temp > upper_bound:
		correction_factor = World.temp_correction_magnitude * (-max(0, (current_avg_temp - target_avg_temp) / target_avg_temp))

	return correction_factor

func adjust_for_season(seasonal_variation: float) -> float:
	var range = World.season_ranges[World.season]
	return map(seasonal_variation, 0, 1, range.x, range.y)

func map(value: float, start1: float, stop1: float, start2: float, stop2: float) -> float:
	return start2 + (stop2 - start2) * ((value - start1) / (stop1 - start1))
