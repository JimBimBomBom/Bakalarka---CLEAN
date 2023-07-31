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

func _process(delta):
	do_time(delta)

func do_vegetation() -> void:
	var vegetation = get_tree().get_nodes_in_group(World.vegetation_group)
	for veg in vegetation:
		pass

# func do_animals() -> void: #currently not in use
# 	var animals = get_tree().get_nodes_in_group(World.animal_group)
# 	for animal in animals:
# 		pass

func do_time(change_in_time) -> void:
	World.hour += change_in_time
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
	if rand <= 0.95: #ADD mb custom probability?
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
	
	
	inst.position = pos*World.tile_size
	inst.add_to_group(World.vegetation_group)
	add_child(inst)

func initialize_npcs():
	var width = World.width
	var height = World.height
	for x in range(-width, width):
		for y in range(-height, height):
			var pos = Vector2(x, y)
			var prob = randf_range(0, 1)
			if between(prob, 0.95, 0.956):
				place_npc(pos, World.Vore_Type.HERBIVORE)
			# elif between(prob, 0.95, 0.96):
			# 	place_npc(pos, World.Vore_Type.CARNIVORE)
			
func place_npc(pos, type):
	var scene #= load("res://SCENES/animal.tscn")
	var inst# = scene.instantiate()
	match type:
		World.Vore_Type.HERBIVORE:
			scene = load("res://SCENES/herbivore.tscn")
			inst = scene.instantiate()
			inst.construct_herbivore(pos)
			inst.get_node("Sprite2D").texture = load("res://Sprites/Herbivore.png")
		World.Vore_Type.CARNIVORE:
			scene = load("res://SCENES/carnivore.tscn")
			inst = scene.instantiate()
			inst.construct_carnivore(pos)
			inst.get_node("Sprite2D").texture = load("res://Sprites/Carnivore.png")

	
	inst.add_to_group(World.animal_group)
	add_child(inst)

func between(val, start, end):
	if start <= val and val <= end:
		return true
	return false
