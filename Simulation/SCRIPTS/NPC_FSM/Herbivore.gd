extends Animal

class_name Herbivore

var consumption_state : Consumption_State = Consumption_State.SEEKING

func herbivore_fsm(delta : float):
	var animals_in_sight : Array[Animal] = get_animals_from_sight()
	# var animals_in_hearing_range : Array[Animal] = get_animals_from_hearing()
	var animals_in_hearing_range = detected_animals
	var dangerous_animals : Array[Animal] = filter_animals_by_danger(animals_in_hearing_range) # TODO add a specific list of dangerous animals to specific animals
	var animals_of_same_type : Array[Animal] = filter_animals_by_type(animals_in_sight, animal_type)
	set_base_state(dangerous_animals)

	match animal_state:
		Animal_Base_States.FLEEING:
			var force = get_flee_dir(dangerous_animals)
			move_calc(force)
		Animal_Base_States.HUNGRY:
			var food_in_range : Array[World.Tile_Properties] = food_in_range()
			if not food_in_range.is_empty(): #GRAZING ?
				herbivore_eat(food_in_range, delta)
			else:
				move_calc(get_roam_dir(animals_of_same_type))
		Animal_Base_States.THIRSTY:
			var hydration_in_range : Array[World.Tile_Properties] = hydration_in_range()
			if not hydration_in_range.is_empty():
				herbivore_hydrate(hydration_in_range, delta)
			else:
				move_calc(get_roam_dir(animals_of_same_type))
		Animal_Base_States.SATED:
			move_calc(get_roam_dir(animals_of_same_type))

func process_animal(delta : float):
	update_animal_norms()
	reset_acceleration() #every "move" is isolated
	herbivore_fsm(delta) # ADD hydration in range

enum Consumption_State {
	CONSUMING,
	SEEKING,
	SCANNING,
}
func herbivore_eat(food_in_range : Array[World.Tile_Properties], delta : float):
	var tile = select_food_tile(food_in_range)
	match consumption_state:
		Consumption_State.SEEKING:
			var target = World.get_tile_pos(tile)
			move_calc(smooth_seek(target))
			if curr_pos.distance_to(target) < 10:
				hearing_range = max_hearing_range*hearing_while_consuming
				consumption_state = Consumption_State.CONSUMING
		Consumption_State.CONSUMING:
			curr_velocity *= 0
			eat_at_tile(tile, delta)
			if tile.curr_food == 0:
				consumption_state = Consumption_State.SEEKING
				hearing_range = max_hearing_range
		Consumption_State.SCANNING:
			hearing_range = max_hearing_range

func herbivore_hydrate(hydration_in_range : Array[World.Tile_Properties], delta : float):
	var tile = select_hydration_tile(hydration_in_range)
	match consumption_state:
		Consumption_State.SEEKING:
			hearing_range = max_hearing_range
			var target = World.get_tile_pos(tile)
			move_calc(smooth_seek(target))
			if curr_pos.distance_to(target) < 10:
				hearing_range = max_hearing_range*hearing_while_consuming
				consumption_state = Consumption_State.CONSUMING
		Consumption_State.CONSUMING:
			curr_velocity *= 0
			drink_at_tile(tile, delta) #TODO reason for animal to change into scanning, can be a timer
			if curr_hydration_norm >= seek_hydration_threshold: #TODO so shit, mb handle using signals?
				consumption_state = Consumption_State.SEEKING
				hearing_range = max_hearing_range
		Consumption_State.SCANNING:
			hearing_range = max_hearing_range

func _on_timer_timeout():
	var delta = 0.1 # once I give animals the chance to influence their delta with a gene -> replace only here
	if animal_state != Animal_Base_States.DEAD:
		process_animal(delta)
	else:
		process_cadaver(delta)

func _physics_process(delta : float):
	do_move(delta)
	position = curr_pos

func get_seek_dir(target : Animal) -> Vector2:
	return curr_pos.direction_to(target.curr_pos).normalized()

func construct_herbivore(pos):
	construct_animal(pos, World.Vore_Type.HERBIVORE)
	animal_type = Animal_Types.DEER
