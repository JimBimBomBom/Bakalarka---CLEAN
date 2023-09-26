extends Animal

class_name Carnivore

var consumption_state : Consumption_State = Consumption_State.SEEKING # separate eating/drinking

func carnivore_fsm(delta : float):
	var animals_in_sight : Array[Animal] = get_animals_from_sight()
	var animals_in_hearing_range : Array[Animal] = detected_animals#get_animals_from_hearing()
	var dangerous_animals : Array[Animal] = filter_animals_by_danger() # TODO add a specific list of dangerous animals to specific animals
	var animals_of_same_type : Array[Animal] = filter_animals_by_type(animals_in_sight, animal_type)
	set_base_state(dangerous_animals)

	match animal_state:
		Animal_Base_States.FLEEING:
			var force = set_next_move(get_flee_dir(dangerous_animals))
		Animal_Base_States.HUNGRY:
			var animals_in_range : Array[Animal] 
			if nutrition_norm < 0.1: #animals_in_hearing_range#filter_animals_by_type(animals_in_hearing_range, Animal_Types.DEER)
				animals_in_range = animals_in_hearing_range # chase closest animal -> even predators
			else:
				animals_in_range = filter_animals_by_type(animals_in_hearing_range, Animal_Types.DEER)

			var cadavers_in_range : Array[Animal] = get_cadavers()
			if not cadavers_in_range.is_empty() or not animals_in_range.is_empty(): #STALKING
				carnivore_eat(animals_in_range, cadavers_in_range, delta)
			else:
				set_next_move(wander())
		Animal_Base_States.THIRSTY:
			var hydration_in_range : Array[World.Tile_Properties] = hydration_in_range()
			if not hydration_in_range.is_empty():
				animal_hydrate(hydration_in_range, delta)
			else:
				set_next_move(wander())
		Animal_Base_States.SATED:
			set_next_move(wander())

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
				set_next_move(smooth_seek(target.position))
				if position.distance_to(target.position) < 10:
					consumption_state = Consumption_State.CONSUMING
			else:
				set_next_move(pursue(target))
				if is_target_in_range(target): #ATTACKING
					consumption_state = Consumption_State.ATTACKING
		Consumption_State.ATTACKING:
			stop_animal()
			fight(target) # maybe the result of fight should tell us what our next_state is (we kill our prey -> consuming)
			consumption_state = Consumption_State.SEEKING
		Consumption_State.CONSUMING: #TODO will consume only half the time.. consume->seek->consum...
			if position.distance_to(target.position) >= 10 or target.animal_state != Animal_Base_States.DEAD:
				consumption_state = Consumption_State.SEEKING
			else:
				eat_animal(target, delta)

func eat_animal(target : Animal, delta : float):
	stop_animal() # we are currently eating -> stop
	var food_gain = delta * 5 #TODO
	if target.mass <= food_gain:
		nutrition += target.mass
		target.free_cadaver()
	else:
		nutrition += food_gain
		target.mass -= food_gain

func is_target_in_range(target : Animal) -> bool:
	if position.distance_to(target.position) < attack_range:
		return true
	return false

func get_stalk_dir(target : Animal) -> Vector2:
	return position.direction_to(target.position + target.curr_velocity).normalized()

func select_target(animals_in_range : Array[Animal], cadavers_in_range : Array[Animal]) -> Animal:
	var result : Animal
	if not cadavers_in_range.is_empty():
		var best_cadaver : Animal = cadavers_in_range[0]
		var curr_best_distance : float = position.distance_to(best_cadaver.position)
		for cadaver in cadavers_in_range:
			var dist_to_target = position.distance_to(cadaver.position) 
			if dist_to_target < curr_best_distance:
				curr_best_distance = dist_to_target
				best_cadaver = cadaver
		result = best_cadaver
	else:
		var best_animal : Animal = animals_in_range[0]
		var curr_best_distance : float = position.distance_to(best_animal.position)
		for animal in animals_in_range:
			var dist_to_target = position.distance_to(animal.position) 
			if dist_to_target < curr_best_distance:
				curr_best_distance = dist_to_target
				best_animal = animal
		result = best_animal

	return result

func animal_hydrate(hydration_in_range : Array[World.Tile_Properties], delta : float):
	var tile = select_hydration_tile(hydration_in_range)
	match consumption_state:
		Consumption_State.SEEKING:
			var target = World.get_tile_pos(tile)
			set_next_move(seek(target))
			if position.distance_to(target) < 10:
				consumption_state = Consumption_State.CONSUMING
		Consumption_State.CONSUMING:
			stop_animal()
			drink_at_tile(delta) #TODO reason for animal to change into scanning, can be a timer
			if hydration_norm >= seek_hydration_norm: #TODO so shit, mb handle using signals?
				consumption_state = Consumption_State.SEEKING

func construct_carnivore(pos):
	construct_animal(pos, World.Vore_Type.CARNIVORE)
	animal_type = Animal_Types.WOLF

func process_animal(delta : float):
	update_animal_norms()
	carnivore_fsm(delta)

func _on_timer_timeout():
	var delta = 0.1
	if animal_state != Animal_Base_States.DEAD:
		process_animal(delta)
	else:
		free_cadaver()

func _physics_process(delta : float):
	do_move(delta)
