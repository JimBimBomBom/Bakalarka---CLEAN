extends Animal

class_name Herbivore

var consumption_state : Consumption_State = Consumption_State.SEEKING
var detected_crops : Array[Food_Crop] = []

func herbivore_fsm(delta : float):
	var animals_in_sight : Array[Animal] = get_animals_from_sight()
	var animals_in_hearing_range = detected_animals
	var dangerous_animals : Array[Animal] = filter_animals_by_danger(animals_in_hearing_range) # TODO add a specific list of dangerous animals to specific animals
	var animals_of_same_type : Array[Animal] = filter_animals_by_type(animals_in_sight, animal_type)
	set_base_state(dangerous_animals)

	match animal_state:
		Animal_Base_States.FLEEING:
			var force = get_flee_dir(dangerous_animals)
			move_calc(force)
		Animal_Base_States.HUNGRY:
			if not detected_crops.is_empty():
				var crop_valid = get_closest_crop()
				if crop_valid[1]:
					herbivore_eat(crop_valid[0], delta)
				else:
					move_calc(get_roam_dir(animals_of_same_type))
			else:
				move_calc(get_roam_dir(animals_of_same_type))
		Animal_Base_States.THIRSTY:
			var hydration_in_range : Array[World.Tile_Properties] = hydration_in_range()
			if not hydration_in_range.is_empty():
				animal_hydrate(hydration_in_range, delta)
			else:
				move_calc(get_roam_dir(animals_of_same_type))
		Animal_Base_States.SATED:
			# if gender == World.Gender.MALE and not reproduced_recently:
			# 	var potential_mates = select_potential_mates()
			# 	if not potential_mates.is_empty():
			# 		reproduce_with_animal(potential_mates[0]) # so far the only heuristic is viscinity
			move_calc(get_roam_dir(animals_of_same_type))

func process_animal(delta : float):
	update_animal_norms()
	reset_acceleration() #every "move" is isolated
	herbivore_fsm(delta)

enum Consumption_State {
	CONSUMING,
	SEEKING,
	# SCANNING,
}
func herbivore_eat(crop, delta : float):
	match consumption_state:
		Consumption_State.SEEKING:
			move_calc(smooth_seek(crop.position))
			if curr_pos.distance_to(crop.position) < 10:
				consumption_state = Consumption_State.CONSUMING
		Consumption_State.CONSUMING:
			stop_animal()
			# hearing_range = max_hearing_range*hearing_while_consuming
			eat_crop(crop)
			consumption_state = Consumption_State.SEEKING
		# Consumption_State.SCANNING:
			# hearing_range = max_hearing_range
			# consumption_state = Consumption_State.SEEKING

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

func get_closest_crop():
	var closest : Food_Crop
	var closest_dist = 1.79769e308
	var edible_crop_was_found = false
	for crop in detected_crops:
		if crop.is_eaten:
			continue
		edible_crop_was_found = true
		var crop_dist = curr_pos.distance_to(crop.position)
		if crop_dist < closest_dist:
			closest_dist = crop_dist
			closest = crop
	return [closest, edible_crop_was_found]

func eat_crop(crop):
	curr_hunger += crop.yield_value * 10 #temporary 10
	crop.be_eaten()

func _on_timer_timeout():
	var delta = 0.1 # once I give animals the chance to influence their delta with a gene -> replace only here
	if animal_state != Animal_Base_States.DEAD:
		process_animal(delta)
	else:
		free_cadaver()

func _physics_process(delta : float):
	do_move(delta)
	position = curr_pos

func _on_Area2D_animal_entered(body):
	if body is Animal and body.curr_pos != curr_pos:
		detected_animals.append(body)
	elif body is Food_Crop:
		detected_crops.append(body)

func _on_Area2D_animal_exited(body):
	if body is Animal:
		detected_animals.erase(body)
	elif body is Food_Crop:
		detected_crops.erase(body)
	
func get_seek_dir(target : Animal) -> Vector2:
	return curr_pos.direction_to(target.curr_pos).normalized()

func construct_herbivore(pos):
	construct_animal(pos, World.Vore_Type.HERBIVORE)
	animal_type = Animal_Types.DEER
