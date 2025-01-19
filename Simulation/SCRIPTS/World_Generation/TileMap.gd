extends TileMapLayer

class_name Tile_Map_Class

enum Noise_Type {
    TEMP,
    ALT,
    MOIST,
}

var tiles = {}

func generate_map(fast_noise, set_seed, freq, oct, oct_gain, max_value):
    fast_noise.noise_type = 1 # SIMPLEX SMOOTH
    # fast_noise.fractal_type = 3
    fast_noise.fractal_type = 1 # FBM (Fractional Brownian Motion)
    fast_noise.frequency = freq
    fast_noise.fractal_octaves = oct
    fast_noise.fractal_gain = oct_gain

    var grid_name = {}
    for y in range(0, World.height):
        for x in range(0, World.width):
            var noise = World.map(fast_noise.get_noise_3d(x, y, set_seed), -1, 1, 0, max_value)
            grid_name[Vector2i(x, y)] = noise
    return grid_name

func generate_world():
    World.temperature = generate_map(World.fast_noise, World.world_seed, 0.07, 10, 0.4, World.max_temperature_noise)
    World.moisture = generate_map(World.fast_noise, World.world_seed, 0.02, 15, 0.3, World.max_moisture_noise)
    World.altitude = generate_map(World.fast_noise, World.world_seed, 0.007, 12, 0.5, World.max_altitude_noise)
    initialize_tile_values()
    # temperature_map()
    # generate_rivers()
    # modify_moisture_based_on_river_proximity()
    set_tiles()

func initialize_tile_values():
    for y in range(0, World.height):
        for x in range(0, World.width):
            # var alt = World.altitude[Vector2i(x, y)]
            var pos = Vector2i(x, y)
            var tile = Tile_Properties.new()
            tile.index = pos
            tile.biome = World.Biome_Type.Uninitialized
            tile.temperature = World.temperature[pos]
            tile.moisture = World.moisture[pos]

            tile.max_hydration = tile.moisture / 2.0
            tile.hydration = tile.max_hydration

            tile.max_plant_matter = min(tile.moisture, tile.temperature) / 4.0
            tile.plant_matter = tile.max_plant_matter / 2.0
            tile.plant_matter_gain = tile.max_plant_matter / 8.0

            tile.total_meat = 0.0
            tile.meat_spoil_rate = 1.0 / tile.temperature
            tile.meat_in_rounds = Array()

            tile.animal_ids = Array()
            tile.scent_trails = Array()
            tiles[pos] = tile
            
func set_tiles():
    for y in range(0, World.height):
        for x in range(0, World.width):
            var pos = Vector2i(x, y)
            var tile = tiles[pos]
            if tile.biome == World.Biome_Type.Uninitialized:
                tile.biome = get_tile_biome(tile.temperature, tile.moisture)
            set_current_cell(pos, tile)

func min_distance_satisfied(pos, points):
    for point in points:
        if World.offset_distance(pos, point) < 2:
            return false
    return true

func get_tile_biome(temp, moist):
    if temp >= 0.75:
        if moist >= 0.65:
            return World.Biome_Type.Tropical_Rainforest
        elif moist >= 0.10:
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

func set_current_cell(pos, tile):
    var sprite_coord = Vector2i(0, 0)
    if tile.biome == World.Biome_Type.Tundra:
        sprite_coord = Vector2i(1, 2)
    elif tile.biome == World.Biome_Type.Taiga:
        sprite_coord = Vector2i(0, 2)
    elif tile.biome == World.Biome_Type.Temperate_Rainforest:
        sprite_coord = Vector2i(0, 1)
    elif tile.biome == World.Biome_Type.Tropical_Rainforest:
        sprite_coord = Vector2i(2, 0)
    elif tile.biome == World.Biome_Type.Temperate_Forest:
        sprite_coord = Vector2i(1, 1)
    elif tile.biome == World.Biome_Type.Savanna:
        sprite_coord = Vector2i(1, 0)
    elif tile.biome == World.Biome_Type.Grassland:
        sprite_coord = Vector2i(2, 1)
    elif tile.biome == World.Biome_Type.Desert:
        sprite_coord = Vector2i(0, 0)
    elif tile.biome == World.Biome_Type.Water:
        sprite_coord = Vector2i(2, 2)
    else:
        print("Biome not found")
    set_cell(pos, 1, sprite_coord)
