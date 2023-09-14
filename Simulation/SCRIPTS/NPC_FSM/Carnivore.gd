extends Animal

class_name Carnivore

var consumption_state : Consumption_State = Consumption_State.SEEKING

func carnivore_fsm(delta : float):
	var animals_in_sight : Array[Animal] = get_animals_from_sight()
	var animals_in_hearing_range : Array[Animal] = detected_animals#get_animals_from_hearing()
	var dangerous_animals : Array[Animal] = filter_animals_by_danger(animals_in_hearing_range) # TODO add a specific list of dangerous animals to specific animals
	var animals_of_same_type : Array[Animal] = filter_animals_by_type(animals_in_sight, animal_type)
	set_base_state(dangerous_animals)

	match animal_state:
		Animal_Base_States.FLEEING:
			var force = get_flee_dir(dangerous_animals)
			move_calc(force)
		Animal_Base_States.HUNGRY:
			var animals_in_range : Array[Animal] 
			if curr_hunger_norm < 0.1: #animals_in_hearing_range#filter_animals_by_type(animals_in_hearing_range, Animal_Types.DEER)
				animals_in_range = animals_in_hearing_range # chase closest animal -> even predators
			else:
				animals_in_range = filter_animals_by_type(animals_in_hearing_range, Animal_Types.DEER)

			var cadavers_in_range : Array[Animal] = get_cadavers_from_smell()
			if not cadavers_in_range.is_empty() or not animals_in_range.is_empty(): #STALKING
				carnivore_eat(animals_in_range, cadavers_in_range, delta)
			else:
				move_calc(get_roam_dir(animals_of_same_type))
		Animal_Base_States.THIRSTY:
			var hydration_in_range : Array[World.Tile_Properties] = hydration_in_range()
			if not hydration_in_range.is_empty():
				animal_hydrate(hydration_in_range, delta)
			else:
				move_calc(get_roam_dir(animals_of_same_type))
		Animal_Base_States.SATED:
			move_calc(get_roam_dir(animals_of_same_type))

enum Consumption_State {
	CONSUMING,
	SEEKING,
	ATTACKING,
}
func carnivore_eat(food_in_range : Array[Animal], cadavers_in_range : Array[Animal], delta : float):
	var target = select_target(food_in_range, cadavers_in_range)
	match consumption_state:
		Consumption_State.SEEKING:
			if target.animal_state == Animal_Base_States.DEAD:
				move_calc(smooth_seek(target.curr_pos))
				if curr_pos.distance_to(target.curr_pos) < 10:
					stop_animal()
					consumption_state = Consumption_State.CONSUMING
			else:
				move_calc(pursue(target))
				if is_target_in_range(target): #ATTACKING
					stop_animal()
					consumption_state = Consumption_State.ATTACKING
		Consumption_State.ATTACKING:
			stop_animal()
			fight(target)
			consumption_state = Consumption_State.SEEKING
		Consumption_State.CONSUMING: #TODO will consume only half the time.. consume->seek->consum...
			stop_animal()
			if not eat_animal(target, delta):
				consumption_state = Consumption_State.SEEKING

func eat_animal(target : Animal, delta : float) -> bool:
	if curr_pos.distance_to(target.curr_pos) >= 10 and target.animal_state != Animal_Base_States.DEAD:
		return false
	var food_gain = delta * 5 #TODO
	if target.mass <= food_gain:
		curr_hunger += target.mass
		#target.mass = 0 # mb we should tell target to free_cadaver()
		target.free_cadaver()
	else:
		curr_hunger += food_gain
		target.mass -= food_gain

	return true

func is_target_in_range(target : Animal) -> bool:
	if curr_pos.distance_to(target.curr_pos) < attack_range:
		return true
	return false

func get_stalk_dir(target : Animal) -> Vector2:
	return curr_pos.direction_to(target.curr_pos + target.curr_velocity).normalized()

func select_target(animals_in_range : Array[Animal], cadavers_in_range : Array[Animal]) -> Animal:
	var result : Animal
	if not cadavers_in_range.is_empty():
		var best_cadaver : Animal = cadavers_in_range[0]
		var curr_best_distance : float = curr_pos.distance_to(best_cadaver.curr_pos)
		for cadaver in cadavers_in_range:
			var dist_to_target = curr_pos.distance_to(cadaver.curr_pos) 
			if dist_to_target < curr_best_distance:
				curr_best_distance = dist_to_target
				best_cadaver = cadaver
		result = best_cadaver
	else:
		var best_animal : Animal = animals_in_range[0]
		var curr_best_distance : float = curr_pos.distance_to(best_animal.curr_pos)
		for animal in animals_in_range:
			var dist_to_target = curr_pos.distance_to(animal.curr_pos) 
			if dist_to_target < curr_best_distance:
				curr_best_distance = dist_to_target
				best_animal = animal
		result = best_animal

	return result

func animal_hydrate(hydration_in_range : Array[World.Tile_Properties], delta : float):
	var tile = select_hydration_tile(hydration_in_range)
	match consumption_state:
		Consumption_State.SEEKING:
			hearing_range = max_hearing_range
			var target = World.get_tile_pos(tile)
			move_calc(smooth_seek(target))
			if curr_pos.distance_to(target) < 10:
				# hearing_range = max_hearing_range*hearing_while_consuming
				consumption_state = Consumption_State.CONSUMING
		Consumption_State.CONSUMING:
			stop_animal()
			drink_at_tile(tile, delta) #TODO reason for animal to change into scanning, can be a timer
			if curr_hydration_norm >= seek_hydration_threshold: #TODO so shit, mb handle using signals?
				consumption_state = Consumption_State.SEEKING
				# hearing_range = max_hearing_range

func construct_carnivore(pos):
	construct_animal(pos, World.Vore_Type.CARNIVORE)
	animal_type = Animal_Types.WOLF

func process_animal(delta : float):
	update_animal_norms()
	reset_acceleration() #every "move" is isolated
	carnivore_fsm(delta)

func _on_timer_timeout():
	var delta = 0.1
	if animal_state != Animal_Base_States.DEAD:
		process_animal(delta)
	else:
		free_cadaver()

func _physics_process(delta : float):
	do_move(delta)
	position = curr_pos
