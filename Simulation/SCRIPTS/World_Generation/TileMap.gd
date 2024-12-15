extends TileMapLayer

class_name Tile_Map_Class

enum Noise_Type {
    TEMP,
    ALT,
    MOIST,
}

var tiles = {}

func generate_map(fast_noise, seed, freq, oct, oct_gain):
    fast_noise.fractal_type = 3
    # fast_noise.seed = randi()

    fast_noise.frequency = freq
    fast_noise.fractal_octaves = oct
    fast_noise.fractal_gain = oct_gain

    var grid_name = {}
    for x in range(-World.width, World.width + 1):
        for y in range(-World.height, World.height + 1):
            var noise = clamp(abs(fast_noise.get_noise_3d(x, y, seed)), 0, 1)
            grid_name[Vector2i(x, y)] = noise
    return grid_name

func generate_world():
    World.temperature = generate_map(World.fast_noise, World.world_seed, 0.005, 10, 0.3)
    World.moisture = generate_map(World.fast_noise, World.world_seed, 0.01, 5, 0.3)
    World.altitude = generate_map(World.fast_noise, World.world_seed, 0.009, 6, 0.4)
    initialize_tile_values()
    set_tiles()

func initialize_tile_values():
    for x in range(-World.width, World.width + 1):
        for y in range(-World.height, World.height + 1):
            var alt = World.altitude[Vector2i(x, y)]
            var pos = Vector2i(x, y)
            var tile = World.Tile_Properties.new()
            if alt < 0.25: # TODO -> placeholder
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

func get_tile_biome(temp, moist):
    if temp >= 0.75:
        if moist >= 0.65:
            return World.Biome_Type.Tropical_Rainforest
        elif moist >= 0.15:
            return World.Biome_Type.Savanna
        else:
            return World.Biome_Type.Desert
    elif temp >= 0.35:
        if moist >= 0.80:
            return World.Biome_Type.Temperate_Rainforest
        elif moist >= 0.35:
            return World.Biome_Type.Temperate_Forest
        elif moist >= 0.05:
            return World.Biome_Type.Grassland
        else:
            return World.Biome_Type.Desert
    elif temp >= 0.15:
        if moist >= 0.20:
            return World.Biome_Type.Taiga
        elif moist >= 0.05:
            return World.Biome_Type.Grassland
        else:
            return World.Biome_Type.Desert
    else:
        return World.Biome_Type.Tundra


func set_current_cell(pos, tile, alt, temp, moist):
    var sprite_coord = Vector2i(0, 0)
    if tile.type == World.Tile_Type.WATER:
        sprite_coord = Vector2i(3, 1)
        tile.biome = World.Biome_Type.Water
    elif tile.type == World.Tile_Type.PLAIN:
        var biome = get_tile_biome(temp, moist)
        tile.biome = biome
        if biome == World.Biome_Type.Tundra:
            sprite_coord = Vector2i(2, 1)
        elif biome == World.Biome_Type.Taiga:
            sprite_coord = Vector2i(1, 1)
        elif biome == World.Biome_Type.Temperate_Rainforest:
            sprite_coord = Vector2i(3, 0)
        elif biome == World.Biome_Type.Tropical_Rainforest:
            sprite_coord = Vector2i(2, 0)
        elif biome == World.Biome_Type.Temperate_Forest:
            sprite_coord = Vector2i(4, 0)
        elif biome == World.Biome_Type.Savanna:
            sprite_coord = Vector2i(1, 0)
        elif biome == World.Biome_Type.Grassland:
            sprite_coord = Vector2i(0, 1)
        elif biome == World.Biome_Type.Desert:
            sprite_coord = Vector2i(0, 0)
    set_cell(pos, 1, sprite_coord)

func calculate_average_2d_array(dict: Dictionary) -> float:
    var sum: float = 0
    var count = 0
    for item in dict.values():
        sum += item
        count += 1
    
    if count > 0:
        return sum / count
    else:
        return 0

# func update_map():
#     var seed = randi() % 100
#     var temp_change = generate_map(World.fast_noise, seed, 0.005, 4, 0.3, false)
#     var moist_change = generate_map(World.fast_noise, seed, 0.005, 1, 0.3, true)

#     var temp_correction_factor = get_balancing_factor()
#     for x in range(-World.width, World.width + 1):
#         for y in range(-World.height, World.height + 1):
#             World.temperature[Vector2i(x, y)] = clamp(World.temperature[Vector2i(x, y)], -1.0, 1.0)

#             var weekly_variation = moist_change[Vector2i(x, y)]
#             weekly_variation = map(weekly_variation, 0, 1, -0.2, 0.2)
#             World.moisture[Vector2i(x, y)] += weekly_variation
#             World.moisture[Vector2i(x, y)] = clamp(World.moisture[Vector2i(x, y)], 0.0, 1.0)

#     set_tiles()
#     World.temperature_avg = calculate_average_2d_array(World.temperature)
#     World.moisture_avg = calculate_average_2d_array(World.moisture)
#     print("Temp avg: ", World.temperature_avg, "\nMoist avg: ", World.moisture_avg, "\n")

# func get_balancing_factor() -> float:
#     var correction_factor = 0
#     var current_avg_temp = World.temperature_avg
#     var target_avg_temp = World.target_avg_temp
#     var lower_bound = target_avg_temp - World.non_extreme_temp_interval
#     var upper_bound = target_avg_temp + World.non_extreme_temp_interval

#     if current_avg_temp < lower_bound:
#         correction_factor = World.temp_correction_magnitude * max(0, (current_avg_temp - target_avg_temp) / target_avg_temp)
#     if current_avg_temp > upper_bound:
#         correction_factor = World.temp_correction_magnitude * (-max(0, (current_avg_temp - target_avg_temp) / target_avg_temp))

#     return correction_factor

# func map(value: float, start1: float, stop1: float, start2: float, stop2: float) -> float:
#     return start2 + (stop2 - start2) * ((value - start1) / (stop1 - start1))
