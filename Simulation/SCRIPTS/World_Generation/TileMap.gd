extends TileMapLayer

class_name Tile_Map_Class

enum Noise_Type {
    TEMP,
    ALT,
    MOIST,
}

var tiles = {}
var tile_labels = {}

# NOTE: I have a max values specified for each noise type to allow us to modify the noise values -> maybe add a minimum value as well?
func generate_map(fast_noise, set_seed, freq, oct, oct_gain, max_value):
    fast_noise.noise_type = 1 # SIMPLEX SMOOTH
    fast_noise.fractal_type = 1 # FBM (Fractional Brownian Motion)
    fast_noise.frequency = freq
    fast_noise.fractal_octaves = oct
    fast_noise.fractal_gain = oct_gain

    var grid = {}
    for y in range(0, World.sim_params.height):
        for x in range(0, World.sim_params.width):
            var noise = World.map(fast_noise.get_noise_3d(x, y, set_seed), -1, 1, 0, max_value)
            grid[Vector2i(x, y)] = noise
    return grid

func generate_world():
    World.temperature = generate_map(World.fast_noise, World.world_seed, 0.03, 10, 0.4, World.max_temperature_noise)
    World.moisture = generate_map(World.fast_noise, World.world_seed, 0.02, 15, 0.3, World.max_moisture_noise)
    World.altitude = generate_map(World.fast_noise, World.world_seed, 0.007, 12, 0.5, World.max_altitude_noise)
    initialize_tile_values()
    initialize_tile_labels()
    # temperature_map()
    # generate_rivers()
    # modify_moisture_based_on_river_proximity()
    set_tiles()

func initialize_tile_values():
    for y in range(0, World.sim_params.height):
        for x in range(0, World.sim_params.width):
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
            tile.meat_spoil_rate = 1.0 / (tile.temperature * 7)
            tile.meat_in_rounds = Array()

            tile.animal_ids = Array()
            tile.scent_trails = Array()
            tiles[pos] = tile
            
func set_tiles():
    for y in range(0, World.sim_params.height):
        for x in range(0, World.sim_params.width):
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

func initialize_tile_labels():
    for y in range(0, World.sim_params.height):
        for x in range(0, World.sim_params.width):
            var pos = Vector2i(x, y)

            # Create a new label
            var label = Label.new()
            label.text = str(10)
            label.add_theme_font_size_override("font", 16)
            label.add_theme_color_override("font_color", Color(0, 0, 0, 1))
            label.visible = false

            # Set alignment properties to center the text
            label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
            label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
            
            # Enable autowrap and minimum size to avoid clipping
            label.custom_minimum_size = Vector2(32, 32)  # Adjust for hex size
            
            # Center the label anchor
            label.anchor_top = 0.5
            label.anchor_bottom = 0.5
            label.anchor_left = 0.5
            label.anchor_right = 0.5

            # Set the label position
            # NOTE: tile position + tile offset for interlocking hex grid + distance between tiles (x, y) and (x, y + 2) is only half the size of a tile
            var world_position =    Vector2i(pos.x * World.tile_size_i.x, pos.y * World.tile_size_i.y) \
                                    + (pos.y % 2) * Vector2i(World.tile_size_i.x / 2, -World.tile_size_i.y / 4) \
                                    - (pos.y / 2) * Vector2i(0, World.tile_size_i.y / 2)
            label.position = world_position

            tile_labels[pos] = label
            World.Map.add_child(label)

func update_map_animal_count_labels():
    var tile_data = World.simulation.get_tile_animal_counts()
    for pos in tile_data.keys():
        var animal_count = tile_data[pos]
        var label = tile_labels[pos]
        if animal_count > 0:
            label.text = str(animal_count)
            label.visible = true
        else:
            label.visible = false
