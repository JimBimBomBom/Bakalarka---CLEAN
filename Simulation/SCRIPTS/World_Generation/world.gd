extends Node2D

func _init():
	World.hour = 0
	World.day = 0
	World.week = 0
	World.season = World.Season_Type.SPRING

func _ready():
	add_child(World.Map)
	World.Map.generate_world()

	add_child(World.Player)
	
	generate_vegetation()
	generate_food_crops()
	initialize_npcs()

	var timer = get_node("HourCounter") 
	timer.timeout.connect(_do_time)

func change_season() -> void:
	World.season += 1
	World.season %= 4 # loop back my 4 seasons

func _do_time() -> void:
	World.hour += 1
	if World.hour >= World.hours_in_day:
		World.day += 1
		if World.day % World.days_in_week == 0:
			World.week += 1
			destroy_food_crop_during_storms()
			generate_food_crops()
			World.Map.update_map()
			if World.week % World.weeks_in_season == 0:
				change_season()
				print("Season: ", World.season)
		World.hour = 0

func generate_food_crops():
	var width = World.width - World.edge_tiles
	var height = World.height - World.edge_tiles
	for x in range(-width, width + 1):
		for y in range(-height, height + 1):
			var pos = Vector2i(x, y)
			# var alt = World.altitude[pos]
			var moist = World.moisture[pos]
			var temp = World.temperature[pos]

			var tile = World.Map.tiles[pos] 
			if tile.type == World.Tile_Type.WATER || tile.occupied || tile.weather == World.Weather_Type.STORM:
				continue
			if moist + randf_range(0, 0.75) <= 1.0: # pretty random
				continue

			if between(moist, 0.4, 0.6) and between(temp, -0.3, 0.9):
				place_food_crop(pos, World.Vegetation_Type.BUSH_1)
			elif between(temp, -0.7, 0.2):
				place_food_crop(pos, World.Vegetation_Type.BUSH_2)

func place_food_crop(pos : Vector2i, type) -> void:
	var	scene = load("res://SCENES/FoodCrop.tscn")
	var inst = scene.instantiate()
	var tile = World.Map.tiles[pos]
	match tile.biome:
		World.Temperature_Type.TAIGA:
			match type:		
				World.Vegetation_Type.BUSH_1:
					inst.get_node("Sprite2D").texture = load("res://Sprites/assets/Bushes/Tropical_Bush_1.png")
				World.Vegetation_Type.BUSH_2:
					inst.get_node("Sprite2D").texture = load("res://Sprites/assets/Bushes/Tropical_Bush_2.png")
		World.Temperature_Type.TEMPERATE_LAND:
			match type:		
				World.Vegetation_Type.BUSH_1: # Cut from here -> tropical in temperate
					inst.get_node("Sprite2D").texture = load("res://Sprites/assets/Bushes/Tropical_Bush_1.png")
				World.Vegetation_Type.BUSH_2:
					inst.get_node("Sprite2D").texture = load("res://Sprites/assets/Bushes/Tropical_Bush_2.png")
		World.Temperature_Type.TROPICAL_LAND:
			match type:		
				World.Vegetation_Type.BUSH_1:
					inst.get_node("Sprite2D").texture = load("res://Sprites/assets/Bushes/Tropical_Bush_1.png")
				World.Vegetation_Type.BUSH_2:
					inst.get_node("Sprite2D").texture = load("res://Sprites/assets/Bushes/Tropical_Bush_2.png")
	
	World.Map.tiles[pos].occupied = true
	inst.tile_index = pos # used to set tile occupancy to false on be_eaten() ...

	inst.position = Vector2(pos.x, pos.y)*World.tile_size
	inst.add_to_group(World.food_crop_group)
	add_child(inst)

func destroy_food_crop_during_storms():
	for crop in get_tree().get_nodes_in_group(World.food_crop_group):
		if World.Map.tiles[crop.tile_index].weather == World.Weather_Type.STORM:
			crop.be_eaten() # be_eaten simply removes the crop from all contexts

func generate_vegetation():
	var width = World.width
	var height = World.height
	for x in range(-width, width + 1):
		for y in range(-height, height + 1):
			var pos = Vector2i(x, y)
			var alt = World.altitude[pos]
			var moist = World.moisture[pos]
			var temp = World.temperature[pos]

			var tile = World.Map.tiles[pos]
			if tile.type == World.Tile_Type.WATER || tile.occupied:
				continue
			if randf_range(0, 1) <= 0.82:
				continue

			if between(alt, -0.45, 0.4) and between(temp, -0.3, 0.8):
				place_vegetation(pos, World.Vegetation_Type.TREE_1)
			elif between(alt, -0.15, 0.7) and between(temp, -0.7, 0.4):
				place_vegetation(pos, World.Vegetation_Type.TREE_2)

func place_vegetation(pos : Vector2i, type) -> void:
	var scene = load("res://SCENES/Vegetation.tscn")
	var inst = scene.instantiate()
	var tile = World.Map.tiles[pos]
	match tile.biome:
		World.Temperature_Type.TAIGA:
			match type:		
				World.Vegetation_Type.TREE_1:
					inst.get_node("Sprite2D").texture = load("res://Sprites/assets/Trees/Taiga_Tree_1.png")
				World.Vegetation_Type.TREE_2: # Cut from here -> tropical in taiga
					inst.get_node("Sprite2D").texture = load("res://Sprites/assets/Trees/Tropical_Tree_2.png")
		World.Temperature_Type.TEMPERATE_LAND:
			match type:		
				World.Vegetation_Type.TREE_1:
					inst.get_node("Sprite2D").texture = load("res://Sprites/assets/Trees/Temperate_Tree_1.png")
				World.Vegetation_Type.TREE_2:
					inst.get_node("Sprite2D").texture = load("res://Sprites/assets/Trees/Temperate_Tree_2.png")
		World.Temperature_Type.TROPICAL_LAND:
			match type:		
				World.Vegetation_Type.TREE_1:
					inst.get_node("Sprite2D").texture = load("res://Sprites/assets/Trees/Tropical_Tree_1.png")
				World.Vegetation_Type.TREE_2:
					inst.get_node("Sprite2D").texture = load("res://Sprites/assets/Trees/Tropical_Tree_2.png")
	
	World.Map.tiles[pos].occupied = true
	inst.position = Vector2(pos.x, pos.y)*World.tile_size
	inst.add_to_group(World.vegetation_group)
	add_child(inst)

func initialize_npcs():
	var width = World.width
	var height = World.height
	for x in range(-width, width + 1):
		for y in range(-height, height + 1):
			var pos = Vector2i(x, y)
			var tile = World.Map.tiles[pos]
			if tile.type == World.Tile_Type.WATER || tile.occupied:
				continue

			var prob = randf_range(0, 1)
			if between(prob, 0.95, 0.956):
				construct_npc(pos, World.Vore_Type.HERBIVORE)
			elif between(prob, 0.956, 0.958):
				construct_npc(pos, World.Vore_Type.CARNIVORE)
			
func construct_npc(pos, type):
	var scene = load("res://SCENES/animal.tscn")
	var inst = scene.instantiate()
	match type:
		World.Vore_Type.HERBIVORE:
			var herbivore_script = load(World.herbivore_script)
			inst.set_script(herbivore_script)
			inst.construct_herbivore(pos)
			inst.get_node("Sprite2D").texture = load("res://Sprites/Herbivore.png")
		World.Vore_Type.CARNIVORE:
			var carnivore_script = load(World.carnivore_script)
			inst.set_script(carnivore_script)
			inst.construct_carnivore(pos)
			inst.get_node("Sprite2D").texture = load("res://Sprites/Carnivore.png")
	inst.add_to_group(World.animal_group)
	inst.birth_request.connect(_on_animal_birth_request)
	add_child(inst)

#End of initialization

func _on_animal_birth_request(pos, type, mother, father):
	var scene = load("res://SCENES/animal.tscn")
	var inst = scene.instantiate()
	match type:
		World.Vore_Type.HERBIVORE:
			var herbivore_script = load(World.herbivore_script)
			inst.set_script(herbivore_script)
			inst.spawn_herbivore(pos, mother.genes, father.genes)
			inst.get_node("Sprite2D").texture = load("res://Sprites/Herbivore.png")
		World.Vore_Type.CARNIVORE:
			var carnivore_script = load(World.carnivore_script)
			inst.set_script(carnivore_script)
			inst.spawn_carnivore(pos, mother.genes, father.genes)
			inst.get_node("Sprite2D").texture = load("res://Sprites/Carnivore.png")
	inst.add_to_group(World.animal_group)
	inst.birth_request.connect(_on_animal_birth_request)
	add_child(inst)

	
func between(val, start, end):
	if start <= val and val <= end:
		return true
	return false
