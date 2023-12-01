extends TileMap

class_name Tile_Map_Class

enum Noise_Type {
	TEMP,
	ALT,
	MOIST,
}

var tiles = {}

func generate_map(fast_noise, seed, freq, oct, oct_gain, abs):
	fast_noise.fractal_type = 3
	# fast_noise.seed = randi()

	fast_noise.frequency = freq
	fast_noise.fractal_octaves = oct
	fast_noise.fractal_gain = oct_gain

	var grid_name = {}
	for x in range(-World.width, World.width + 1):
		for y in range(-World.height, World.height + 1):
			var noise
			if abs:
				noise = clamp(abs(fast_noise.get_noise_3d(x, y, seed)), 0, 1)
			else:
				noise = clamp(fast_noise.get_noise_3d(x, y, seed), -1, 1)
			grid_name[Vector2i(x, y)] = noise
	return grid_name

func generate_world():
	World.temperature = generate_map(World.fast_noise, World.world_seed, 0.005, 10, 0.3, false)
	World.moisture = generate_map(World.fast_noise, World.world_seed, 0.01, 5, 0.3, true)
	World.altitude = generate_map(World.fast_noise, World.world_seed, 0.009, 6, 0.4, false)
	initialize_tile_values()
	set_tiles()

func initialize_tile_values():
	for x in range(-World.width, World.width + 1):
		for y in range(-World.height, World.height + 1):
			var alt = World.altitude[Vector2i(x, y)]
			var pos = Vector2i(x, y)
			var tile = World.Tile_Properties.new() 
			if alt < -0.45:
				tile.type = World.Tile_Type.WATER
			else:
				tile.type = World.Tile_Type.PLAIN
			tile.occupied = false
			tile.position = Vector2(pos.x * World.tile_size.x, pos.y * World.tile_size.y)
			tile.index = pos
			tiles[pos] = tile
			
func set_tiles():
	for x in range(-World.width, World.width + 1):
		for y in range(-World.height, World.height + 1):
			var pos = Vector2i(x, y)
			var alt = World.altitude[pos]
			var moist = World.moisture[pos]
			var temp = World.temperature[pos]
			var tile = tiles[pos]
			set_current_cell(pos, tile, alt, temp, moist)

func get_type_from_temp(temp):
	var temp_type : World.Temperature_Type
	if temp < -0.4:
		temp_type = World.Temperature_Type.TAIGA
	elif temp < 0.3:
		temp_type = World.Temperature_Type.TEMPERATE_LAND
	else:
		temp_type = World.Temperature_Type.TROPICAL_LAND
	return temp_type

func get_tile_weather(moist : float) -> World.Weather_Type:
	var weather : World.Weather_Type
	if moist < 0.4:
		weather = World.Weather_Type.CLEAR
	elif moist < 0.6:
		weather = World.Weather_Type.CLOUDY
	elif moist < 0.9:
		weather = World.Weather_Type.RAIN
	else:
		weather = World.Weather_Type.STORM
	return weather

func set_current_cell(pos, tile, alt, temp, moist):
	var temperature_type = get_type_from_temp(temp)
	tile.biome = temperature_type
	tile.weather = get_tile_weather(moist)
	var sprite_coord = Vector2i(0, 0) # base plain tile coord
	if tile.type == World.Tile_Type.WATER:
		sprite_coord = Vector2i(2, 2) # base water tile coord
	set_cell(0, pos, temperature_type, sprite_coord) # temperature_type defines the ID of our Tile_Set,

func update_map():
	var seed = randi() % 100
	var temp_change = generate_map(World.fast_noise, seed, 0.005, 4, 0.3, false)
	var moist_change = generate_map(World.fast_noise, seed, 0.005, 1, 0.3, true)

	var temp_correction_factor = get_balancing_factor()
	for x in range(-World.width, World.width + 1):
		for y in range(-World.height, World.height + 1):
			var seasonal_variation = temp_change[Vector2i(x, y)]
			seasonal_variation = adjust_for_season(seasonal_variation)
			World.temperature[Vector2i(x, y)] += seasonal_variation #+ temp_correction_factor 
			World.temperature[Vector2i(x, y)] = clamp(World.temperature[Vector2i(x, y)], -1.0, 1.0)

			var weekly_variation = moist_change[Vector2i(x, y)]
			weekly_variation = map(weekly_variation, 0, 1, -0.2, 0.2)
			World.moisture[Vector2i(x, y)] += weekly_variation
			World.moisture[Vector2i(x, y)] = clamp(World.moisture[Vector2i(x, y)], 0.0, 1.0)

	set_tiles()
	World.temperature_avg = calculate_average_2d_array(World.temperature)
	World.moisture_avg = calculate_average_2d_array(World.moisture)
	print("Temp avg: ", World.temperature_avg, "\nMoist avg: ", World.moisture_avg, "\n")

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
	var lower_bound = target_avg_temp - World.non_extreme_temp_interval
	var upper_bound = target_avg_temp + World.non_extreme_temp_interval

	if current_avg_temp < lower_bound:
		correction_factor = World.temp_correction_magnitude * max(0, (current_avg_temp - target_avg_temp) / target_avg_temp)
	if current_avg_temp > upper_bound:
		correction_factor = World.temp_correction_magnitude * (-max(0, (current_avg_temp - target_avg_temp) / target_avg_temp))

	return correction_factor

func adjust_for_season(seasonal_variation: float) -> float:
	var range = World.season_ranges[World.season]
	return map(seasonal_variation, -1, 1, range.x, range.y)

func map(value: float, start1: float, stop1: float, start2: float, stop2: float) -> float:
	return start2 + (stop2 - start2) * ((value - start1) / (stop1 - start1))
