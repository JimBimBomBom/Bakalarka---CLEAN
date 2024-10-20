extends Animal

class_name Herbivore

var detected_crops: Array[Food_Crop] = []

func herbivore_fsm(delta: float):
	var animals_in_sight: Array[Animal] = get_animals_from_sight()
	var animals_in_hearing_range = detected_animals
	var dangerous_animals: Array[Animal] = filter_animals_by_danger()
	var animals_of_same_type: Array[Animal] = filter_animals_by_type(animals_in_sight, animal_type)
	set_base_state(dangerous_animals)

	match animal_state:
		Animal_Base_States.FLEEING:
			consumption_state = Consumption_State.SEEKING # if an animal was eating/drinking when a danger entered its area if should not remain in consuming state
			set_next_move(get_flee_dir(dangerous_animals))
		Animal_Base_States.HUNGRY:
			if not detected_crops.is_empty():
				var crop = get_closest_crop()
				herbivore_eat(crop, delta)
			else:
				set_next_move(wander())
		Animal_Base_States.THIRSTY:
			var hydration_in_range: Array[World.Tile_Properties] = hydration_in_range()
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
					set_next_move(wander())
			else: # eat/drink closest
				var crop
				var water_tile

				var hydration_in_range: Array[World.Tile_Properties] = hydration_in_range()
				if not hydration_in_range.is_empty():
					water_tile = select_hydration_tile(hydration_in_range)
				if not detected_crops.is_empty():
					crop = get_closest_crop()

				if crop and water_tile:
					if position.distance_to(crop.position) < position.distance_to(water_tile.position):
						herbivore_eat(crop, delta)
					else:
						animal_hydrate(water_tile, delta)
				elif crop:
					herbivore_eat(crop, delta)
				elif water_tile:
					animal_hydrate(water_tile, delta)
				else:
					set_next_move(wander())

func herbivore_eat(crop, delta: float):
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

func get_closest_crop():
	var closest: Food_Crop = detected_crops[0]
	var closest_dist = position.distance_to(closest.position) # detected crops is not empty
	for crop in detected_crops:
		var crop_dist = position.distance_to(crop.position)
		if crop_dist < closest_dist:
			closest_dist = crop_dist
			closest = crop
	return closest

func eat_crop(crop):
	nutrition += crop.yield_value
	crop.be_eaten()
	
func spawn_herbivore(pos, parent_1, parent_2):
	spawn_animal(pos, World.Vore_Type.HERBIVORE, parent_1, parent_2)
	animal_type = Animal_Types.DEER

func construct_herbivore(pos):
	construct_animal(pos, World.Vore_Type.HERBIVORE)
	animal_type = Animal_Types.DEER

func _physics_process(delta: float):
	do_timers(delta) # each physics step -> only step we use, increment timers and execute if needed
	update_animal_resources(delta)
	herbivore_fsm(delta)
	do_move(delta)

func _on_Area2D_food_crop_entered(body):
	var body_parent = body.get_parent()
	if body_parent is Food_Crop:
		detected_crops.append(body_parent)

func _on_Area2D_food_crop_exited(body):
	var body_parent = body.get_parent()
	if body_parent is Food_Crop:
		detected_crops.erase(body_parent)

func _ready():
	change_age_timer = SimulationTimer.new()
	change_age_timer.trigger_time = change_age_period
	change_age_timer.active = true
	change_age_timer.timer_triggered.connect(_on_change_age_timer_timeout)

	sex_cooldown_timer = SimulationTimer.new()
	sex_cooldown_timer.trigger_time = sex_cooldown
	sex_cooldown_timer.active = true
	sex_cooldown_timer.timer_triggered.connect(_on_sex_cooldown_timeout)

	var animal_detector = get_node("Area_Detection")
	animal_detector.body_entered.connect(_on_Area2D_animal_entered)
	animal_detector.body_exited.connect(_on_Area2D_animal_exited)

	# Herbivores will detect food crops
	animal_detector.area_entered.connect(_on_Area2D_food_crop_entered)
	animal_detector.area_exited.connect(_on_Area2D_food_crop_exited)

	var detection_radius = get_node("Area_Detection").get_node("Detection_Radius")
	detection_radius.shape.radius = genes.sense_range
	print(detection_radius.shape.radius)
