extends TileMap

enum Noise_Type {
	TEMP,
	ALT,
	MOIST,
	}
	
func _init():
	generate_world()
	generate_vegetation()
	initialize_npcs()

func generate_vegetation():
	var width = World.width
	var height = World.height

	for x in range(-width, width):
		for y in range(-height, height):
			var pos = Vector2(x, y)
			var alt = World.altitude[pos]
			var moist = World.moisture[pos]
			var temp = World.temperature[pos]

			if between(moist, 0.6, 0.8) and between(temp, 0.4, 0.8):
				place_tree(pos, World.Vegetation_Type.TREE_1)
			elif between(moist, 0.6, 0.8) and between(temp, 0.0, 0.4):
				place_tree(pos, World.Vegetation_Type.TREE_2)
			elif between(moist, 0.4, 0.6) and between(temp, 0.0, 0.8):
				place_tree(pos, World.Vegetation_Type.BUSH_1)
			elif between(moist, 0.4, 0.6) and between(temp, 0.0, 0.8):
				place_tree(pos, World.Vegetation_Type.BUSH_2)

func place_tree(pos, type) -> void:
	var rand = randf_range(0, 1)
	if rand <= 0.95:
		return
	var scene = load("res://SCENES/Vegetation.tscn")
	var inst = scene.instantiate()
	match type:		
		World.Vegetation_Type.TREE_1:
			inst.get_node("Sprite2D").texture = load("res://Sprites/assets/tree_1.png")
		World.Vegetation_Type.TREE_2:
			inst.get_node("Sprite2D").texture = load("res://Sprites/assets/tree_2.png")
		World.Vegetation_Type.BUSH_1:
			inst.get_node("Sprite2D").texture = load("res://Sprites/assets/bush_1.png")
		World.Vegetation_Type.BUSH_2:
			inst.get_node("Sprite2D").texture = load("res://Sprites/assets/bush_2.png")
	
	
	inst.position = pos*Vector2(16, 16)
	#get_parent().call_deferred("add_child", inst)
	add_child(inst)

func initialize_npcs():
	var width = World.width
	var height = World.height
	for x in range(-width, width):
		for y in range(-height, height):
			var pos = Vector2(x, y)
			var prob = randf_range(0, 100)
			if between(prob, 0.96, 0.98):
				place_npc(pos, World.Vore_Type.HERBIVORE)
			elif between(prob, 0.99, 1.03):
				place_npc(pos, World.Vore_Type.CARNIVORE)
			
func place_npc(pos, type):
	var scene
	match type:
		World.Vore_Type.HERBIVORE:
			scene = load("res://SCENES/npc.tscn")
		World.Vore_Type.CARNIVORE:
			scene = load("res://SCENES/npc.tscn")
		World.Vore_Type.OMNIVORE:
			scene = load("res://SCENES/npc.tscn")

	var inst = scene.instantiate()
	match type:
		World.Vore_Type.HERBIVORE:
			inst.constructor(pos, 100, 2, 0.3, type)
			inst.get_node("Sprite2D").texture = load("res://Sprites/Herbivore.png")
		World.Vore_Type.CARNIVORE:
			inst.constructor(pos, 300, 2.3, 0.1, type)
			inst.get_node("Sprite2D").texture = load("res://Sprites/Carnivore.png")

	inst.add_to_group("NPCs")
	add_child(inst)
	#owner.call_deferred("add_child", inst)


func generate_map(fast_noise, type, width, height, freq, oct, oct_gain):
	fast_noise.fractal_type = 3
	fast_noise.seed = randi()

	fast_noise.frequency = freq
	fast_noise.fractal_octaves = oct
	fast_noise.fractal_gain = oct_gain

	var grid_name = {}
	for x in range(-width, width):
		for y in range(-height, height):
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
	for x in range(-width, width):
		for y in range(-height, height):
			var pos = Vector2(x, y)
			var alt = World.altitude[pos]
			var moist = World.moisture[pos]
			var temp = World.temperature[pos]
			new_set_current_cell(alt, temp, moist, pos)
			
			
func between(val, start, end):
	if start <= val and val <= end:
		return true
	return false

func new_set_current_cell(alt, temp, moist, pos):
	var sprite_coords = Vector2i(0, 0)
	if moist < 0.05:
		sprite_coords = Vector2i(2, 2)
	#land
	else:
		sprite_coords = Vector2i(0, 0)

	set_cell(0, pos, 0, sprite_coords)
