extends Animal

class_name Herbivore

func herbivore_fsm(delta : float,
					dangerous_animals : Array[Animal], animals_of_same_type : Array[Animal],
					food_in_range : Array[World.Tile_Properties]):
	match animal_state:
		Animal_Base_States.FLEEING:
			var force = get_flee_dir(dangerous_animals)
			move_new(force)
		Animal_Base_States.SLEEPING:
			curr_velocity = Vector2(0, 0)
		Animal_Base_States.HUNGRY:
			if not food_in_range.is_empty(): #GRAZING ?
				pass #TODO add behaviour
			else:
				move_new(get_roam_dir(animals_of_same_type))
		Animal_Base_States.THIRSTY:
			# if not hydration_in_range.is_empty():
			# 	pass
			# else:
			move_new(get_roam_dir(animals_of_same_type))
		Animal_Base_States.SATED:
			rest(delta)

func process_animal(delta : float):
	var animals_in_sight : Array[Animal] = get_animals_from_sight()
	var animals_in_hearing_range : Array[Animal] = get_animals_from_hearing()
	var dangerous_animals : Array[Animal] = filter_animals_by_danger(animals_in_hearing_range) # TODO add a specific list of dangerous animals to specific animals
	var animals_of_same_type : Array[Animal] = filter_animals_by_type(animals_in_sight, animal_type)
	var food_in_range : Array[World.Tile_Properties] = food_in_range()

	set_base_state(dangerous_animals)
	herbivore_fsm(delta, dangerous_animals, animals_of_same_type, food_in_range) # ADD hydration in range

func _physics_process(delta : float):
	position = curr_pos
	if animal_state != Animal_Base_States.DEAD:
		process_animal(delta)
	else:
		process_cadaver(delta)

func get_seek_dir(target : Animal) -> Vector2:
	return curr_pos.direction_to(target.curr_pos).normalized()

func construct_herbivore(pos):
	construct_animal(pos, World.Vore_Type.HERBIVORE)
	animal_type = Animal_Types.DEER

func food_in_range() -> Array[World.Tile_Properties]:
	var result : Array[World.Tile_Properties]
	var tiles = get_tiles_from_senses()
	for tile in tiles:
		if tile.tile_type == World.Tile_Type.PLAIN and tile.curr_food > 0:
			result.append(tile)
	return result
	


