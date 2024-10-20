extends Animal_Characteristics

class_name Animal

enum Animal_Base_States {
	SATED,
	HUNGRY,
	THIRSTY,
	FLEEING,
}
enum Consumption_State {
	CONSUMING,
	SEEKING,
	ATTACKING,
}
enum Animal_Types {
	WOLF,
	DEER,
}

signal birth_request(pos, type, parent_1, parent_2)
signal death(pos, mass)

var change_age_timer: SimulationTimer
var sex_cooldown_timer: SimulationTimer
# var cadaver_timer: SimulationTimer

var animal_state: Animal_Base_States = Animal_Base_States.SATED
var consumption_state: Consumption_State = Consumption_State.SEEKING

var genes: Animal_Genes = Animal_Genes.new()
var animal_type: Animal_Types
var detected_animals: Array[Animal] = [] # right now every animal is detected
# could add animals_in_range to mean all animals within our Detection_Radius
# + detected_animals for animals that we are aware of being in our radius

func spawn_animal(pos, type, mother, father):
	genes.pass_down_genes(mother, father)
	vore_type = type
	set_characteristics(genes)
	position = Vector2(pos.x, pos.y) # here the position is not in tile coordinates
	animal_state = Animal_Base_States.SATED
	if vore_type == World.Vore_Type.CARNIVORE:
		World.carnivore_count += 1
	else:
		World.herbivore_count += 1

func construct_animal(pos: Vector2i, type: World.Vore_Type):
	genes.generate_genes()
	vore_type = type
	set_characteristics(genes)
	position = Vector2(pos.x, pos.y) * World.tile_size
	animal_state = Animal_Base_States.SATED
	generation = 0 # NOTE: here animals are created to populate the initial world, so in effect they represent the 0th generation of randomly generated animals
	if vore_type == World.Vore_Type.CARNIVORE:
		World.carnivore_count += 1
	else:
		World.herbivore_count += 1

func kill_animal():
	death.emit(position, self)
	if vore_type == World.Vore_Type.CARNIVORE:
		World.carnivore_count -= 1
	else:
		World.herbivore_count -= 1
	# remove_from_group(World.animal_group)
	queue_free()

# should handle "consumption state"(which is also a bad name), where the base state "resets"
# every other state not affiliated with our current base state -> HUNGRY sets drinking_state to SEEKING and vice versa
func set_base_state(dangerous_animals: Array[Animal]):
	if energy <= 0 or health <= 0:
		kill_animal()
	elif not dangerous_animals.is_empty():
		animal_state = Animal_Base_States.FLEEING
	elif animal_state == Animal_Base_States.SATED:
		if nutrition_norm < seek_nutrition_norm and nutrition_norm < hydration_norm:
			animal_state = Animal_Base_States.HUNGRY
		elif hydration_norm < seek_hydration_norm and hydration_norm < nutrition_norm:
			animal_state = Animal_Base_States.THIRSTY
	elif animal_state == Animal_Base_States.HUNGRY:
		if nutrition_norm > seek_nutrition_norm and hydration_norm < seek_hydration_norm and nutrition_norm < seek_nutrition_norm:
			animal_state = Animal_Base_States.THIRSTY
		elif nutrition_norm >= nutrition_satisfied_norm:
			animal_state = Animal_Base_States.SATED
		# if nutrition_norm >= nutrition_satisfied_norm: 
		# 	animal_state = Animal_Base_States.SATED
	elif animal_state == Animal_Base_States.THIRSTY:
		# if nutrition_norm < seek_nutrition_norm and hydration_norm < seek_hydration_norm:
		# 	animal_state = Animal_Base_States.HUNGRY
		# elif hydration_norm >= hydration_satisfied_norm:
		# 	animal_state = Animal_Base_States.SATED
		if hydration_norm >= hydration_satisfied_norm:
			animal_state = Animal_Base_States.SATED

func reset_acceleration():
	desired_velocity *= 0.01

func stop_animal():
	velocity *= 0.01
	desired_velocity *= 0.01

func free_cadaver():
	remove_from_group(World.cadaver_group)
	queue_free()

# TODO: refactor:
	#metabolic rate tells us the largest ammount of a resource that can be converted to energy
func resource_calc(delta: float):
	var resource_loss = metabolic_rate * delta
	var energy_gain = 0
	if nutrition >= resource_loss:
		energy_gain += resource_loss
		nutrition -= resource_loss
	else:
		energy_gain += nutrition
		nutrition = 0
		# TODO consequences

	if hydration >= resource_loss:
		energy_gain += resource_loss
		hydration -= resource_loss
	else:
		energy_gain += hydration
		hydration = 0
		# TODO consequences

	var energy_drain_delta = energy_drain * delta / 10 # drain is an animals' characteristic
	energy += energy_gain - energy_drain_delta

func update_animal_resources(delta: float):
	resource_calc(delta)
	energy_norm = energy / max_resources
	nutrition_norm = nutrition / max_resources
	hydration_norm = hydration / max_resources
	health_norm = health / max_health

func can_see(pos) -> bool:
	if abs(position.distance_to(pos)) < genes.vision_range and abs(position.angle_to(pos)) < genes.field_of_view_half:
		return true
	return false

func get_animals_from_sight() -> Array[Animal]:
	var result: Array[Animal]
	for animal in detected_animals:
		if can_see(animal.position):
			result.append(animal)
	return result

func get_cadavers() -> Array[Cadaver]:
	var result: Array[Cadaver]
	for animal in detected_animals:
		if animal.is_in_group(World.cadaver_group):
			result.append(animal)
	return result

# TODO: make everyone using this function use filter_animals_by_type instead
func filter_animals_by_danger() -> Array[Animal]:
	var dangerous_animals: Array[Animal]
	for animal in detected_animals:
		if animal.is_in_group(World.animal_group) and vore_type == World.Vore_Type.HERBIVORE and animal.vore_type == World.Vore_Type.CARNIVORE:
			dangerous_animals.append(animal)
	return dangerous_animals

func filter_animals_by_type(animals_in_sight: Array[Animal], type: Animal_Types):
	var animals_of_type: Array[Animal]
	for animal in animals_in_sight:
		if type == animal.animal_type:
			animals_of_type.append(animal)
	return animals_of_type

# TODO: make everyone using this function use filter_animals_by_type instead + filter out animals that can't have sex
func find_closest_mate(animals_of_same_type: Array[Animal]) -> Animal:
	var result: Animal = animals_of_same_type[0]
	var closest_animal: float = position.distance_to(animals_of_same_type[0].position)
	for animal in animals_of_same_type:
		if animal.can_have_sex:
			var dist = position.distance_to(animal.position)
			if dist < closest_animal:
				result = animal
				closest_animal = dist
	return result
		
func fight(defender: Animal) -> void: # mb have a combat log -> combat instance with participants(many herbivores fighting off a carnivore etc.)
	defender.health -= attack_damage

func within_bounds(tile_index: Vector2) -> bool:
	if tile_index.x > -World.width and tile_index.x < World.width and tile_index.y > -World.height and tile_index.y < World.height:
		return true
	return false

func max(a: int, b: int) -> int:
	if a > b:
		return a
	return b

func get_tiles_from_senses() -> Array[World.Tile_Properties]:
	var result: Array[World.Tile_Properties]
	var tiles_in_direction: int = max(1, genes.sense_range / World.tile_size.x)
	var curr_tile_ind: Vector2i = position / World.tile_size

	var center_of_tile: Vector2i = World.tile_size / 2
	var curr_tile_pos: Vector2i = curr_tile_ind * World.tile_size_i + center_of_tile
	for x in range(-tiles_in_direction, tiles_in_direction):
		for y in range(-tiles_in_direction, tiles_in_direction):
			var x_pos = curr_tile_pos.x + x * World.tile_size_i.x
			var y_pos = curr_tile_pos.y + y * World.tile_size_i.y
			var tile_index = curr_tile_ind + Vector2i(x, y)
			if within_bounds(tile_index) and position.distance_to(Vector2(x_pos, y_pos)) < genes.sense_range:
				result.append(World.Map.tiles[tile_index])
	return result

func hydration_in_range() -> Array[World.Tile_Properties]:
	var result: Array[World.Tile_Properties]
	var tiles = get_tiles_from_senses()
	for tile in tiles:
		if tile.type == World.Tile_Type.WATER:
			result.append(tile)
	return result

func select_hydration_tile(tiles: Array[World.Tile_Properties]) -> World.Tile_Properties:
	var result: World.Tile_Properties = tiles[0] # tiles is not empty if we are in this function
	for tile in tiles:
		var tmp: World.Tile_Properties = tile
		if position.distance_to(World.get_tile_pos(tmp)) < position.distance_to(World.get_tile_pos(result)):
			result = tmp
	return result

func drink_at_tile(delta: float):
	hydration += delta * 10 # just delta is painfully slow

func animal_hydrate(water_tile, delta: float):
	match consumption_state:
		Consumption_State.SEEKING:
			var target = World.get_tile_pos(water_tile)
			set_next_move(smooth_seek(target))
			if position.distance_to(target) < 10:
				consumption_state = Consumption_State.CONSUMING
		Consumption_State.CONSUMING:
			stop_animal()
			drink_at_tile(delta) # TODO reason for animal to change into scanning, can be a timer
			if hydration_norm >= 1: # TODO so shit, mb handle using signals?
				consumption_state = Consumption_State.SEEKING

func select_potential_mates(animals_of_same_type: Array[Animal]) -> Array[Animal]:
	var result: Array[Animal]
	for animal in animals_of_same_type:
		if animal.can_have_sex and animal.animal_state == Animal_Base_States.SATED:
			result.append(animal)
	return result

func select_mating_partner(potential_mates: Array[Animal]) -> Animal:
	var best_dist = position.distance_to(potential_mates[0].position)
	var selected_mate = potential_mates[0]
	for mate in potential_mates:
		var curr_dist = position.distance_to(mate.position)
		if curr_dist < best_dist:
			best_dist = curr_dist
			selected_mate = mate
	return selected_mate

func reproduce_with_animal(animal: Animal):
	can_have_sex = false
	sex_cooldown_timer.active = true
	nutrition -= World.reproduction_nutrition_cost*max_resources

	animal.can_have_sex = false
	animal.sex_cooldown_timer.active = true
	animal.nutrition -= World.reproduction_nutrition_cost*animal.max_resources

	birth_request.emit(position, vore_type, self, animal)

func process_animal(delta: float):
	pass # this function gets defined individually for Carnivores/Herbivores

#Node component functions:

func _on_Area2D_animal_entered(body):
	if body is Animal and body.position != position:
		detected_animals.append(body)

func _on_Area2D_animal_exited(body):
	if body is Animal:
		detected_animals.erase(body)

func _on_action_timeout():
	pass

func _on_free_cadaver_timeout():
	free_cadaver()

func _on_change_age_timer_timeout():
	if age == World.Age_Group.OLD:
		kill_animal()
	else:
		age += 1

func _on_sex_cooldown_timeout():
	can_have_sex = true

func do_timers(delta: float):
	change_age_timer.do_timer(delta) 
	if sex_cooldown_timer.active:
		sex_cooldown_timer.do_timer(delta, true)

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

	var detection_radius = get_node("Area_Detection").get_node("Detection_Radius")
	detection_radius.shape.radius = genes.sense_range
