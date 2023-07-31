extends Animal

class_name Carnivore

func carnivore_fsm(dangerous_animals : Array[Animal], food_in_range : Array[Animal]):
	match animal_state:
		Animal_Base_States.FLEEING:
			var force = get_flee_dir(dangerous_animals)
			move_new(force)
		Animal_Base_States.SLEEPING:
			curr_velocity = Vector2(0, 0)
		Animal_Base_States.HUNGRY:
			if not food_in_range.is_empty(): #STALKING
				var target = select_target(food_in_range)
				var force = pursue(target) # TODO get_stalking_dir -> where prey will be
				move_new(force)
				if is_target_in_range(target): #ATTACKING
					fight(target)
			else:
				# move_new(rand_walk()) #ROAMING
				move_new(wander()) #ROAMING
		Animal_Base_States.THIRSTY:
		# 	if not hydration_in_range.is_empty():
		# 		pass
		# 	else:
			move_new(wander()) #ROAMING
		Animal_Base_States.SATED:
			move_new(wander()) #ROAMING

func process_animal(delta : float):
	var animals_in_sight : Array[Animal] = get_animals_from_sight()
	var animals_in_hearing_range : Array[Animal] = get_animals_from_hearing()
	var dangerous_animals : Array[Animal] = filter_animals_by_danger(animals_in_hearing_range) # TODO add a specific list of dangerous animals to specific animals
	var animals_of_same_type : Array[Animal] = filter_animals_by_type(animals_in_sight, animal_type)
	var food_in_range : Array[Animal] = filter_animals_by_type(animals_in_hearing_range, Animal_Types.DEER)

	set_base_state(dangerous_animals)
	carnivore_fsm(dangerous_animals, food_in_range) # ADD hydration in range

func _physics_process(delta : float):
	position = curr_pos
	if animal_state != Animal_Base_States.DEAD:
		process_animal(delta)
	else:
		process_cadaver(delta)

func is_target_in_range(target : Animal) -> bool:
	if curr_pos.distance_to(target.curr_pos) < attack_range:
		return true
	return false

func get_stalk_dir(target : Animal) -> Vector2:
	return curr_pos.direction_to(target.curr_pos + target.curr_velocity).normalized()

func select_target_for_attack(animals_in_attack_range : Array[Animal]) -> Animal:
	var best_target : Animal
	var curr_best_distance : float = 1.79769e300
	for animal in animals_in_attack_range:
		var dist_to_target = curr_pos.distance_to(animal.curr_pos) 
		if dist_to_target < curr_best_distance:
			curr_best_distance = dist_to_target
			best_target = animal
	return best_target

func select_target(food_in_range : Array[Animal]) -> Animal:
	var best_target : Animal
	var curr_best_distance : float = 1.79769e300
	for animal in food_in_range:
		var dist_to_target = curr_pos.distance_to(animal.curr_pos) 
		if dist_to_target < curr_best_distance:
			curr_best_distance = dist_to_target
			best_target = animal

	return best_target

func construct_carnivore(pos):
	construct_animal(pos, World.Vore_Type.CARNIVORE)
	animal_type = Animal_Types.WOLF
