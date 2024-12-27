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
    fast_noise.frequency = freq
    fast_noise.fractal_octaves = oct
    fast_noise.fractal_gain = oct_gain

    var grid_name = {}
    for x in range(0, World.width + 1):
        for y in range(0, World.height + 1):
            var noise = clamp(abs(fast_noise.get_noise_3d(x, y, seed)), 0, 1)
            grid_name[Vector2i(x, y)] = noise
    return grid_name

func generate_world():
    World.temperature = generate_map(World.fast_noise, World.world_seed, 0.009, 10, 0.4)
    World.moisture = generate_map(World.fast_noise, World.world_seed, 0.005, 15, 0.3)
    World.altitude = generate_map(World.fast_noise, World.world_seed, 0.009, 6, 0.4)
    adjust_temperature_for_latitude()
    initialize_tile_values()
    set_tiles()

func adjust_temperature_for_latitude():
    for x in range(0, World.width + 1):
        for y in range(0, World.height + 1):
            var pos = Vector2i(x, y)
            World.temperature[pos] += 0.6 # NOTE: makes the area around the equator warmer
            World.temperature[pos] -= 3*abs((World.height / 2) - y) / (World.height * 1.0)

func initialize_tile_values():
    for x in range(0, World.width + 1):
        for y in range(0, World.height + 1):
            var alt = World.altitude[Vector2i(x, y)]
            var pos = Vector2i(x, y)
            var tile = World.Tile_Properties.new()
            tile.index = pos
            if alt < World.water_level_altitude: # TODO -> placeholder
                tile.biome = World.Biome_Type.Water
            else:
                tile.biome = get_tile_biome(World.temperature[pos], World.moisture[pos])
            tile.temperature = World.temperature[pos]
            tile.moisture = World.moisture[pos]
            tile.plant_life = 0.0
            tile.meat = 0.0
            tile.animals = []
            tiles[pos] = tile
            
func set_tiles():
    for x in range(0, World.width + 1):
        for y in range(0, World.height + 1):
            var pos = Vector2i(x, y)
            var tile = tiles[pos]
            set_current_cell(pos, tile)

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

# func update_map():
