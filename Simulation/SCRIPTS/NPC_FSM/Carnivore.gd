extends Animal

class_name Carnivore

var cadavers_in_range : Array[Cadaver] = []

func carnivore_fsm(delta : float):
	var animals_in_sight : Array[Animal] = get_animals_from_sight()
	var animals_in_hearing_range : Array[Animal] = detected_animals#get_animals_from_hearing()
	var dangerous_animals : Array[Animal] = filter_animals_by_danger() # TODO add a specific list of dangerous animals to specific animals
	var animals_of_same_type : Array[Animal] = filter_animals_by_type(animals_in_sight, animal_type)
	set_base_state(dangerous_animals)

	match animal_state:
		Animal_Base_States.FLEEING:
			set_next_move(get_flee_dir(dangerous_animals))
		Animal_Base_States.HUNGRY:
			var cadavers_in_range : Array[Cadaver] = get_cadavers()
			var prey_in_range = filter_animals_by_type(detected_animals, Animal_Types.DEER)
			if not cadavers_in_range.is_empty():# or not animals_in_range.is_empty(): #STALKING
				var target = select_cadaver(cadavers_in_range)
				carnivore_seek_cadaver(target, delta)
			elif not prey_in_range.is_empty():
				var target = select_target(prey_in_range)
				hunt_animal(target, delta)
			else:
				set_next_move(wander())
		Animal_Base_States.THIRSTY:
			var hydration_in_range : Array[World.Tile_Properties] = hydration_in_range()
			if not hydration_in_range.is_empty():
				var water_tile = select_hydration_tile(hydration_in_range)
				animal_hydrate(water_tile, delta)
			else:
				set_next_move(wander())
		Animal_Base_States.SATED:
			if can_have_sex:
				var potential_mates = select_potential_mates(animals_of_same_type)
				if not potential_mates.is_empty():
					var mate = select_mating_partner(potential_mates)
					reproduce_with_animal(mate) # so far the only heuristic is viscinity
			else:
				var target
				var water_tile

				var cadavers_in_range : Array[Cadaver] = get_cadavers()
				var prey_in_range = filter_animals_by_type(detected_animals, Animal_Types.DEER)
				if not cadavers_in_range.is_empty():# or not animals_in_range.is_empty(): #STALKING
					target = select_cadaver(cadavers_in_range)
					carnivore_seek_cadaver(target, delta)
				elif not prey_in_range.is_empty():
					target = select_target(prey_in_range)
					hunt_animal(target, delta)
				else:
					var hydration_in_range : Array[World.Tile_Properties] = hydration_in_range()
					if not hydration_in_range.is_empty():
						water_tile = select_hydration_tile(hydration_in_range)
					else:
						set_next_move(wander())

func carnivore_seek_cadaver(target : Cadaver, delta : float):
	match consumption_state:
		Consumption_State.SEEKING:
			set_next_move(smooth_seek(target.position))
			if position.distance_to(target.position) < 10:
				consumption_state = Consumption_State.CONSUMING
		Consumption_State.CONSUMING: #TODO will consume only half the time.. consume->seek->consum...
			eat_cadaver(target, delta)

func hunt_animal(target : Animal, delta : float):
	match consumption_state:
		Consumption_State.SEEKING:
			set_next_move(seek(target.position))
			if is_target_in_range(target): #ATTACKING
				consumption_state = Consumption_State.ATTACKING
		Consumption_State.ATTACKING:
			stop_animal()
			fight(target) # maybe the result of fight should tell us what our next_state is (we kill our prey -> consuming)
			consumption_state = Consumption_State.SEEKING

func eat_cadaver(target : Cadaver, delta : float):
	stop_animal() # we are currently eating -> stop
	var food_gain = delta * 10 #TODO
	if target.nutrition <= food_gain:
		nutrition += target.nutrition
		target._free_cadaver()
	else:
		nutrition += food_gain
		target.nutrition -= food_gain

func is_target_in_range(target : Animal) -> bool:
	if position.distance_to(target.position) < attack_range:
		return true
	return false

func get_stalk_dir(target : Animal) -> Vector2:
	return position.direction_to(target.position + target.curr_velocity).normalized()

func select_cadaver(cadavers_in_range : Array[Cadaver]) -> Cadaver:
	var result : Cadaver = cadavers_in_range[0]
	var curr_best_distance : float = position.distance_to(result.position)
	for cadaver in cadavers_in_range:
		var dist_to_target = position.distance_to(cadaver.position) 
		if dist_to_target < curr_best_distance:
			curr_best_distance = dist_to_target
			result = cadaver
	return result

func select_target(animals_in_range : Array[Animal]) -> Animal:
	var result : Animal = animals_in_range[0]
	var curr_best_distance : float = position.distance_to(result.position)
	for animal in animals_in_range:
		var dist_to_target = position.distance_to(animal.position) 
		if dist_to_target < curr_best_distance:
			curr_best_distance = dist_to_target
			result = animal
	return result

func animal_hydrate(water_tile, delta : float):
	match consumption_state:
		Consumption_State.SEEKING:
			var target = World.get_tile_pos(water_tile)
			set_next_move(seek(target))
			if position.distance_to(target) < 10:
				consumption_state = Consumption_State.CONSUMING
		Consumption_State.CONSUMING:
			stop_animal()
			drink_at_tile(delta) #TODO reason for animal to change into scanning, can be a timer
			if hydration_norm >= seek_hydration_norm: #TODO so shit, mb handle using signals?
				consumption_state = Consumption_State.SEEKING

func spawn_carnivore(pos, mother, father):
	spawn_animal(pos, World.Vore_Type.CARNIVORE, mother, father)
	animal_type = Animal_Types.WOLF

func construct_carnivore(pos):
	construct_animal(pos, World.Vore_Type.CARNIVORE)
	animal_type = Animal_Types.WOLF

func _physics_process(delta : float):
	do_timers(delta) # each physics step -> only step we use, increment timers and execute if needed
	update_animal_resources(delta)
	carnivore_fsm(delta)
	do_move(delta)

func _on_Area2D_animal_entered(body):
	if body.is_in_group(World.cadaver_group):
		cadavers_in_range.append(body)
		return
	if body.position != position:
		detected_animals.append(body)

func _on_Area2D_animal_exited(body):
	if body.is_in_group(World.cadaver_group):
		cadavers_in_range.erase(body)
		return
	detected_animals.erase(body)
