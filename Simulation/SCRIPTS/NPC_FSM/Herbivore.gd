extends Animal

class_name Herbivore

var consumption_state : Consumption_State = Consumption_State.SEEKING
var detected_crops : Array[Food_Crop] = []

func herbivore_fsm(delta : float):
	var animals_in_sight : Array[Animal] = get_animals_from_sight()
	var animals_in_hearing_range = detected_animals
	var dangerous_animals : Array[Animal] = filter_animals_by_danger()
	var animals_of_same_type : Array[Animal] = filter_animals_by_type(animals_in_sight, animal_type)
	set_base_state(dangerous_animals)

	match animal_state:
		Animal_Base_States.FLEEING:
			set_next_move(get_flee_dir(dangerous_animals))
		Animal_Base_States.HUNGRY:
			if not detected_crops.is_empty():
				var crop = get_closest_crop()
				herbivore_eat(crop, delta)
			else:
				set_next_move(wander())
		Animal_Base_States.THIRSTY:
			var hydration_in_range : Array[World.Tile_Properties] = hydration_in_range()
			if not hydration_in_range.is_empty():
				animal_hydrate(hydration_in_range, delta)
			else:
				set_next_move(wander())
		Animal_Base_States.SATED:
			if genes.gender == World.Gender.MALE and can_have_sex:
				var potential_mates = select_potential_mates(animals_of_same_type)
				if not potential_mates.is_empty():
					var mate = select_mating_partner(potential_mates)
					reproduce_with_animal(mate) # so far the only heuristic is viscinity
			set_next_move(wander())

enum Consumption_State {
	CONSUMING,
	SEEKING,
}
func herbivore_eat(crop, delta : float):
	match consumption_state:
		Consumption_State.SEEKING:
			set_next_move(smooth_seek(crop.position))
			if position.distance_to(crop.position) < 10:
				consumption_state = Consumption_State.CONSUMING
		Consumption_State.CONSUMING:
			if position.distance_to(crop.position) >= 10:
				consumption_state = Consumption_State.SEEKING
			else:
				stop_animal()
				eat_crop(crop)
				consumption_state = Consumption_State.SEEKING

func animal_hydrate(hydration_in_range : Array[World.Tile_Properties], delta : float):
	var tile = select_hydration_tile(hydration_in_range)
	match consumption_state:
		Consumption_State.SEEKING:
			var target = World.get_tile_pos(tile)
			set_next_move(smooth_seek(target))
			if position.distance_to(target) < 10:
				consumption_state = Consumption_State.CONSUMING
		Consumption_State.CONSUMING:
			stop_animal()
			drink_at_tile(delta) #TODO reason for animal to change into scanning, can be a timer
			if hydration_norm >= seek_hydration_norm: #TODO so shit, mb handle using signals?
				consumption_state = Consumption_State.SEEKING

func get_closest_crop():
	var closest : Food_Crop = detected_crops[0]
	var closest_dist = position.distance_to(closest.position) # detected crops is not empty
	for crop in detected_crops:
		var crop_dist = position.distance_to(crop.position)
		if crop_dist < closest_dist:
			closest_dist = crop_dist
			closest = crop
	return closest

func eat_crop(crop):
	nutrition += crop.yield_value * 10 #temporary 10
	crop.be_eaten()
	
func spawn_herbivore(pos, mother, father):
	spawn_animal(pos, World.Vore_Type.HERBIVORE, mother, father)
	animal_type = Animal_Types.WOLF

func construct_herbivore(pos):
	construct_animal(pos, World.Vore_Type.HERBIVORE)
	animal_type = Animal_Types.DEER

func process_animal(delta : float):
	update_animal_resources(delta)
	herbivore_fsm(delta)

func _on_timer_timeout():
	var delta = 0.1 # once I give animals the chance to influence their delta with a gene -> replace only here
	if animal_state != Animal_Base_States.DEAD: # could separate branches into functions + set timer to appropriate func
		process_animal(delta)
	else:
		free_cadaver()

func _physics_process(delta : float):
	do_move(delta)

func _on_Area2D_animal_entered(body):
	if body is Animal and body.position != position:
		detected_animals.append(body)
	elif body is Food_Crop:
		detected_crops.append(body)

func _on_Area2D_animal_exited(body):
	if body is Animal:
		detected_animals.erase(body)
	elif body is Food_Crop:
		detected_crops.erase(body)
	
