extends Node2D

func _init():
	World.day = 0
	World.day_type = World.Day_Type.DAY
	World.hour = 0
	World.hours_in_day = 60

func _ready():
	add_child(World.Map)
	World.Map.generate_world()

	add_child(World.Player)
	
	generate_vegetation()
	initialize_npcs()

	var timer = get_node("Timer") 
	timer.timeout.connect(_do_time)

func do_vegetation() -> void:
	var vegetation = get_tree().get_nodes_in_group(World.vegetation_group)
	for veg in vegetation:
		pass

func _do_time() -> void:
	World.hour += 1
	if World.hour >= World.hours_in_day:
		World.day += 1
		if World.day % 7 == 0:
			do_vegetation() #TODO maybe send signal to vegetation instead
		World.hour = 0
		World.day_type = World.Day_Type.DAY
	if World.hour > World.hours_in_day/2:
		World.day_type = World.Day_Type.NIGHT 

func generate_vegetation():
	var width = World.width
	var height = World.height
	for x in range(-width, width):
		for y in range(-height, height):
			var pos = Vector2i(x, y)
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
	if rand <= 0.75: #ADD mb custom probability?
		return
	var scene = load("res://SCENES/Vegetation.tscn")
	var inst = scene.instantiate()
	var tile = World.Map.tiles[pos]
	match tile.biome:
		#World.Temperature_Type.TUNDRA:
			#match type:	
				#pass	
				# World.Vegetation_Type.TREE_1:
				# 	inst.get_node("Sprite2D").texture = load("res://Sprites/assets/Trees/Temperate_Tree_1.png")
				# World.Vegetation_Type.TREE_2:
				# 	inst.get_node("Sprite2D").texture = load("res://Sprites/assets/Trees/Temperate_Tree_2.png")
				# World.Vegetation_Type.BUSH_1:
				# 	inst.get_node("Sprite2D").texture = load("res://Sprites/assets/Bushes/Tropical_Bush_1.png")
				# World.Vegetation_Type.BUSH_2:
				# 	inst.get_node("Sprite2D").texture = load("res://Sprites/assets/Bushes/Tropical_Bush_2.png")
		World.Temperature_Type.TAIGA:
			match type:		
				World.Vegetation_Type.TREE_1:
					inst.get_node("Sprite2D").texture = load("res://Sprites/assets/Trees/Taiga_Tree_1.png")
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
				World.Vegetation_Type.BUSH_1:
					inst.get_node("Sprite2D").texture = load("res://Sprites/assets/Bushes/Tropical_Bush_1.png")
				World.Vegetation_Type.BUSH_2:
					inst.get_node("Sprite2D").texture = load("res://Sprites/assets/Bushes/Tropical_Bush_2.png")
		World.Temperature_Type.DESERT:
			match type:		
				World.Vegetation_Type.TREE_1:
					inst.get_node("Sprite2D").texture = load("res://Sprites/assets/Trees/Cactus_1.png")
				World.Vegetation_Type.BUSH_1:
					inst.get_node("Sprite2D").texture = load("res://Sprites/assets/Bushes/Jungle_Bush_1.png")
				World.Vegetation_Type.BUSH_2:
					inst.get_node("Sprite2D").texture = load("res://Sprites/assets/Bushes/Jungle_Bush_1.png")
	
	inst.position = Vector2(pos.x, pos.y)*World.tile_size
	inst.add_to_group(World.vegetation_group)
	add_child(inst)

func initialize_npcs():
	var width = World.width
	var height = World.height
	place_npc(Vector2(0, 0), World.Vore_Type.HERBIVORE)
	place_npc(Vector2(2, 3), World.Vore_Type.CARNIVORE)
	for x in range(-width, width):
		for y in range(-height, height):
			var pos = Vector2(x, y)
			var prob = randf_range(0, 1)
			if between(prob, 0.95, 0.956):
				place_npc(pos, World.Vore_Type.HERBIVORE)
			elif between(prob, 0.956, 0.958):
				place_npc(pos, World.Vore_Type.CARNIVORE)
			
func place_npc(pos, type):
	var scene = load("res://SCENES/animal.tscn")
	var inst = scene.instantiate()
	match type:
		World.Vore_Type.HERBIVORE:
			# scene = load("res://SCENES/herbivore.tscn")
			# inst = scene.instantiate()
			var herbivore_script = load(World.herbivore_script)
			#var node = get_node("CharacterBody2D")
			#node.set_script(herbivore_script)
			inst.set_script(herbivore_script)
			inst.construct_herbivore(pos)
			inst.get_node("Sprite2D").texture = load("res://Sprites/Herbivore.png")
		World.Vore_Type.CARNIVORE:
			# scene = load("res://SCENES/carnivore.tscn")
			# inst = scene.instantiate()
			var carnivore_script = load(World.carnivore_script)
			#var node = get_node("CharacterBody2D")
			#node.set_script(carnivore_script)
			inst.set_script(carnivore_script)
			inst.construct_carnivore(pos)
			inst.get_node("Sprite2D").texture = load("res://Sprites/Carnivore.png")

	
	inst.add_to_group(World.animal_group)
	add_child(inst)

func between(val, start, end):
	if start <= val and val <= end:
		return true
	return false
