extends Node2D

func _ready():
    var map_scene = load("res://SCENES/tile_map.tscn")
    World.Map = map_scene.instantiate()
    add_child(World.Map)
    World.Map.generate_world()

    World.x_edge_from_center = World.width * World.tile_size.x
    World.y_edge_from_center = World.height * World.tile_size.y

    add_child(World.Player)

    generate_vegetation()
    generate_food_crops()
    initialize_npcs()
        
    World.game_speed_controller.set_game_speed(World.game_speed)

    World.food_regrow_timer = SimulationTimer.new()
    World.food_regrow_timer.trigger_time = World.food_regrow_time
    World.food_regrow_timer.active = true
    World.food_regrow_timer.timer_triggered.connect(_regrow_food)

func _regrow_food() -> void:
    generate_food_crops()

func generate_food_crops():
    var width = World.width
    var height = World.height
    for x in range(-width, width + 1):
        for y in range(-height, height + 1):
            var pos = Vector2i(x, y)
            var moist = World.moisture[pos]
            var temp = World.temperature[pos]

            var tile = World.Map.tiles[pos] 
            if tile.type == World.Tile_Type.WATER || tile.occupied:
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
                    inst.find_child("Sprite2D").texture = load("res://Sprites/assets/Bushes/Tropical_Bush_1.png")
                World.Vegetation_Type.BUSH_2:
                    inst.find_child("Sprite2D").texture = load("res://Sprites/assets/Bushes/Tropical_Bush_2.png")
        World.Temperature_Type.TEMPERATE_LAND:
            match type:		
                World.Vegetation_Type.BUSH_1: # Cut from here -> tropical in temperate
                    inst.find_child("Sprite2D").texture = load("res://Sprites/assets/Bushes/Tropical_Bush_1.png")
                World.Vegetation_Type.BUSH_2:
                    inst.find_child("Sprite2D").texture = load("res://Sprites/assets/Bushes/Tropical_Bush_2.png")
        World.Temperature_Type.TROPICAL_LAND:
            match type:		
                World.Vegetation_Type.BUSH_1:
                    inst.find_child("Sprite2D").texture = load("res://Sprites/assets/Bushes/Tropical_Bush_1.png")
                World.Vegetation_Type.BUSH_2:
                    inst.find_child("Sprite2D").texture = load("res://Sprites/assets/Bushes/Tropical_Bush_2.png")
    
    World.Map.tiles[pos].occupied = true
    inst.tile_index = pos # used to set tile occupancy to false on be_eaten() ...

    inst.position = Vector2(pos.x, pos.y)*World.tile_size
    add_child(inst)

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
                    inst.find_child("Sprite2D").texture = load("res://Sprites/assets/Trees/Taiga_Tree_1.png")
                World.Vegetation_Type.TREE_2: # Cut from here -> tropical in taiga
                    inst.find_child("Sprite2D").texture = load("res://Sprites/assets/Trees/Tropical_Tree_2.png")
        World.Temperature_Type.TEMPERATE_LAND:
            match type:		
                World.Vegetation_Type.TREE_1:
                    inst.find_child("Sprite2D").texture = load("res://Sprites/assets/Trees/Temperate_Tree_1.png")
                World.Vegetation_Type.TREE_2:
                    inst.find_child("Sprite2D").texture = load("res://Sprites/assets/Trees/Temperate_Tree_2.png")
        World.Temperature_Type.TROPICAL_LAND:
            match type:		
                World.Vegetation_Type.TREE_1:
                    inst.find_child("Sprite2D").texture = load("res://Sprites/assets/Trees/Tropical_Tree_1.png")
                World.Vegetation_Type.TREE_2:
                    inst.find_child("Sprite2D").texture = load("res://Sprites/assets/Trees/Tropical_Tree_2.png")
    
    World.Map.tiles[pos].occupied = true
    inst.position = Vector2(pos.x, pos.y)*World.tile_size
    add_child(inst)

func initialize_npcs():
    for i in range(World.herbivore_count):
        var pos = Vector2i(randi_range(-World.width, World.width), randi_range(-World.height, World.height))
        construct_npc(pos, World.Vore_Type.HERBIVORE)
    for i in range(World.carnivore_count):
        var pos = Vector2i(randi_range(-World.width, World.width), randi_range(-World.height, World.height))
        construct_npc(pos, World.Vore_Type.CARNIVORE)

func construct_npc(pos, type):
    match type:
        World.Vore_Type.HERBIVORE:
            var scene = load("res://SCENES/herbivore.tscn")
            var inst = scene.instantiate()
            var herbivore_script = load(World.herbivore_script)
            inst.set_script(herbivore_script)
            inst.construct_herbivore(pos)
            inst.find_child("Sprite2D").texture = load("res://Sprites/Herbivore.png")
            inst.birth_request.connect(_on_animal_birth_request)
            add_child(inst)
        World.Vore_Type.CARNIVORE:
            var scene = load("res://SCENES/carnivore.tscn")
            var inst = scene.instantiate()
            var carnivore_script = load(World.carnivore_script)
            inst.set_script(carnivore_script)
            inst.construct_carnivore(pos)
            inst.find_child("Sprite2D").texture = load("res://Sprites/Carnivore.png")
            inst.birth_request.connect(_on_animal_birth_request)
            add_child(inst)

#End of initialization

func _on_animal_birth_request(pos, type, parent_1, parent_2):
    match type:
        World.Vore_Type.HERBIVORE:
            var scene = load("res://SCENES/herbivore.tscn")
            var inst = scene.instantiate()
            var herbivore_script = load(World.herbivore_script)
            inst.set_script(herbivore_script)
            inst.spawn_herbivore(pos, parent_1.genes, parent_2.genes)
            inst.find_child("Sprite2D").texture = load("res://Sprites/Herbivore.png")
            inst.generation = max(parent_1.generation, parent_2.generation) + 1
            inst.birth_request.connect(_on_animal_birth_request)
            add_child(inst)
        World.Vore_Type.CARNIVORE:
            var scene = load("res://SCENES/carnivore.tscn")
            var inst = scene.instantiate()
            var carnivore_script = load(World.carnivore_script)
            inst.set_script(carnivore_script)
            inst.spawn_carnivore(pos, parent_1.genes, parent_2.genes)
            inst.find_child("Sprite2D").texture = load("res://Sprites/Carnivore.png")
            inst.generation = max(parent_1.generation, parent_2.generation) + 1
            inst.birth_request.connect(_on_animal_birth_request)
            add_child(inst)

func between(val, start, end):
    if start <= val and val <= end:
        return true
    return false

# func _process(delta):
# 	if Input.is_action_just_pressed("toggle_camera"):
# 		self.visible = not self.visible		

func do_timers(delta):
    World.food_regrow_timer.do_timer(delta) # this timer will always be active

func _physics_process(delta):
    do_timers(delta)
    World.game_time += delta
