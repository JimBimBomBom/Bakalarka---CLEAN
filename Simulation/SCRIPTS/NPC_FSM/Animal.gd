extends Animal_Characteristics

class_name Animal

enum Animal_Base_States {
	INIT,
	DEAD,
	SATED,
	HUNGRY,
	THIRSTY,
	FLEEING,
	# SLEEPING,
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

var animal_state : Animal_Base_States = Animal_Base_States.INIT
var consumption_state : Consumption_State = Consumption_State.SEEKING

var genes : Animal_Genes = Animal_Genes.new()
var animal_type : Animal_Types 
var detected_animals : Array[Animal] = [] # right now every animal is detected
# could add animals_in_range to mean all animals within our Detection_Radius
# + detected_animals for animals that we are aware of being in our radius

func spawn_animal(pos, type, mother, father):
	genes.pass_down_genes(mother, father)
	vore_type = type
	set_characteristics(genes)
	position = Vector2(pos.x, pos.y) * World.tile_size

	generation = max(mother.generation, father.generation) + 1 # NOTE: generation is only interesting for graphing the composition of the population

func construct_animal(pos : Vector2i, type : World.Vore_Type):
	genes.generate_genes()
	vore_type = type
	set_characteristics(genes)
	position = Vector2(pos.x, pos.y) * World.tile_size

	generation = 0 # NOTE: here animals are created to populate the initial world, so in effect they represent the 0th generation of randomly generated animals

func kill_animal():
	animal_state = Animal_Base_States.DEAD
	stop_animal()
	remove_from_group(World.animal_group) 
	add_to_group(World.cadaver_group)
	var timer = get_node("Timer") # hijack decision timer + set its' wait_time
	timer.stop()
	timer.timeout.connect(_on_free_cadaver_timeout)
	timer.wait_time = World.corpse_timer # TODO add decomposition based on tile temperature, etc.
	timer.start()

# should handle "consumption state"(which is also a bad name), where the base state "resets"
# every other state not affiliated with our current base state -> HUNGRY sets drinking_state to SEEKING and vice versa
func set_base_state(dangerous_animals : Array[Animal]):
	if energy <= 0 or health <= 0:
		kill_animal()
	elif not dangerous_animals.is_empty():
		animal_state = Animal_Base_States.FLEEING
	elif nutrition_norm < seek_nutrition_norm: # and nutrition_norm < hydration_norm:
		animal_state = Animal_Base_States.HUNGRY
	elif hydration_norm < seek_hydration_norm:
		animal_state = Animal_Base_States.THIRSTY
	else:
		animal_state = Animal_Base_States.SATED

func reset_acceleration():
	desired_velocity *= 0

func stop_animal():
	velocity *= 0
	desired_velocity *= 0

func free_cadaver():
	remove_from_group(World.cadaver_group)
	self.queue_free()

func resource_calc(delta : float):
	var resource_loss = metabolic_rate*delta*World.base_resource_use
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

	var energy_drain_delta = energy_drain*delta # drain is an animals' characteristic
	var total_energy_gain = energy_gain * World.energy_per_resource_gain
	energy += total_energy_gain - energy_drain_delta

func update_animal_resources(delta : float):
	resource_calc(delta)
	energy_norm = energy/max_resources
	nutrition_norm = nutrition/max_resources
	hydration_norm = hydration/max_resources
	health_norm = health/max_health

func can_see(pos) -> bool:
	if abs(position.distance_to(pos)) < genes.vision_range and abs(position.angle_to(pos)) < genes.field_of_view_half:
		return true
	return false

func get_animals_from_sight() -> Array[Animal]:
	var result : Array[Animal]
	for animal in detected_animals:
		if can_see(animal.position):
			result.append(animal)
	return result

func get_cadavers() -> Array[Animal]:
	var result : Array[Animal]
	for animal in detected_animals:
		if animal.is_in_group(World.cadaver_group):
			result.append(animal)
	return result

func filter_animals_by_danger() -> Array[Animal]:
	var dangerous_animals : Array[Animal]
	for animal in detected_animals:
		if animal.is_in_group(World.animal_group) and vore_type == World.Vore_Type.HERBIVORE and animal.vore_type == World.Vore_Type.CARNIVORE:
			dangerous_animals.append(animal)
	return dangerous_animals

func filter_animals_by_type(animals_in_sight : Array[Animal], type : Animal_Types):
	var animals_of_type : Array[Animal]
	for animal in animals_in_sight:
		if type == animal.animal_type:
			animals_of_type.append(animal)
	return animals_of_type

func find_closest_mate(animals_of_same_type : Array[Animal]) -> Animal:
	var result : Animal = animals_of_same_type[0]
	var closest_animal : float = position.distance_to(animals_of_same_type[0].position)
	for animal in animals_of_same_type:
		if animal.gender == World.Gender.FEMALE:
			var dist = position.distance_to(animal.position)
			if dist < closest_animal:
				result = animal
				closest_animal = dist
	return result
		
func fight(defender : Animal) -> void: # mb have a combat log -> combat instance with participants(many herbivores fighting off a carnivore etc.)
	defender.health -= attack_damage
	#if randf_range(0, 1) < World.fight_back_chance:
	#	health -= defender.attack_damage

func within_bounds(tile_index : Vector2) -> bool:
	if tile_index.x > -World.width and tile_index.x < World.width and tile_index.y > -World.height and tile_index.y < World.height:
		return true
	return false

func max(a : int, b : int) -> int:
	if a > b:
		return a
	return b

func get_tiles_from_senses() -> Array[World.Tile_Properties]:
	var result : Array[World.Tile_Properties]
	var tiles_in_direction : int = max(1, genes.sense_range / World.tile_size.x)
	var curr_tile_ind : Vector2i = position / World.tile_size

	var center_of_tile : Vector2i = World.tile_size/2
	var curr_tile_pos : Vector2i = curr_tile_ind * World.tile_size_i + center_of_tile
	for x in range(-tiles_in_direction, tiles_in_direction):
		for y in range(-tiles_in_direction, tiles_in_direction):
			var x_pos = curr_tile_pos.x + x*World.tile_size_i.x 
			var y_pos = curr_tile_pos.y + y*World.tile_size_i.y 
			var tile_index = curr_tile_ind + Vector2i(x, y)
			if within_bounds(tile_index) and position.distance_to(Vector2(x_pos, y_pos)) < genes.sense_range:
				result.append(World.Map.tiles[tile_index])
	return result

func hydration_in_range() -> Array[World.Tile_Properties]:
	var result : Array[World.Tile_Properties]
	var tiles = get_tiles_from_senses()
	for tile in tiles:
		if tile.type == World.Tile_Type.WATER: 
			result.append(tile)
	return result

func select_hydration_tile(tiles: Array[World.Tile_Properties]) -> World.Tile_Properties:
	var result : World.Tile_Properties = tiles[0] # tiles is not empty if we are in this function
	for tile in tiles:
		var tmp : World.Tile_Properties = tile
		if position.distance_to(World.get_tile_pos(tmp)) < position.distance_to(World.get_tile_pos(result)):
			result = tmp
	return result

# Water tiles are infinite atm... could be change to be a finite resource? probably not
func drink_at_tile(delta : float):#, tile : World.Tile_Properties):
	hydration += delta

func animal_hydrate(water_tile, delta : float):
	match consumption_state:
		Consumption_State.SEEKING:
			var target = World.get_tile_pos(water_tile)
			set_next_move(smooth_seek(target))
			if position.distance_to(target) < 10:
				consumption_state = Consumption_State.CONSUMING
		Consumption_State.CONSUMING:
			stop_animal()
			drink_at_tile(delta) #TODO reason for animal to change into scanning, can be a timer
			if hydration_norm >= 1: #TODO so shit, mb handle using signals?
				consumption_state = Consumption_State.SEEKING

func select_potential_mates(animals_of_same_type : Array[Animal]) -> Array[Animal]:
	var result : Array[Animal]
	for animal in animals_of_same_type:
		if animal.genes.gender == World.Gender.FEMALE and animal.can_have_sex:
			result.append(animal)
	return result

func select_mating_partner(potential_mates : Array[Animal]) -> Animal:
	var best_dist = position.distance_to(potential_mates[0].position)
	var selected_mate = potential_mates[0]
	for mate in potential_mates:
		var curr_dist = position.distance_to(mate.position)
		if curr_dist < best_dist:
			best_dist = curr_dist
			selected_mate = mate
	return selected_mate

func reproduce_with_animal(animal : Animal):
	can_have_sex = false
	animal.become_pregnant(self)
	get_node("sex_cooldown").start()

func become_pregnant(partner : Animal):
	can_have_sex = false
	sexual_partner = partner
	get_node("pregnancy_timer").start()

func process_animal(delta : float):
	pass # this function gets defines individually for Carnivores/Herbivores

#Node component functions:
func _on_pregnancy_timer_timeout():
	for i in range(0, genes.num_of_offspring):
		birth_request.emit(position, vore_type, self, sexual_partner)
	can_have_sex = true
	sexual_partner = null

func _on_sex_cooldown_timeout():
	can_have_sex = true

func _on_Area2D_animal_entered(body):
	if body is Animal and body.position != position:
		detected_animals.append(body)

func _on_Area2D_animal_exited(body):
	if body is Animal:
		detected_animals.erase(body)

func _on_action_timeout():
	var delta = processing_speed # once I give animals the chance to influence their delta with a gene -> replace only here
	process_animal(delta)

func _on_free_cadaver_timeout():
	free_cadaver()

func _on_change_age_timer_timeout():
	if age == World.Age_Group.OLD:
		kill_animal()
	else:
		age += 1
		get_node("change_age_timer").start()

func _ready():
	var action_timer = get_node("Timer") #?? mb add timeout for actions as an animal variable? could be interesting
	action_timer.set_wait_time(processing_speed)
	action_timer.timeout.connect(_on_action_timeout)

	var age_timer = Timer.new() 
	age_timer.set_name("change_age_timer")
	age_timer.set_wait_time(change_age_period)
	age_timer.set_one_shot(true)
	age_timer.timeout.connect(_on_change_age_timer_timeout)
	add_child(age_timer)
	age_timer.start()

	var sex_timer = Timer.new()
	if genes.gender == World.Gender.FEMALE:
		sex_timer.set_name("pregnancy_timer")
		sex_timer.set_wait_time(genes.pregnancy_duration)
		sex_timer.set_one_shot(true)
		sex_timer.timeout.connect(_on_pregnancy_timer_timeout)
		add_child(sex_timer)
	else:
		sex_timer.set_name("sex_cooldown")
		sex_timer.set_wait_time(genes.male_sex_cooldown)
		sex_timer.set_one_shot(true)
		sex_timer.timeout.connect(_on_sex_cooldown_timeout)
		add_child(sex_timer)

	
	var animal_detector = get_node("Area_Detection")
	animal_detector.body_entered.connect(_on_Area2D_animal_entered)
	animal_detector.body_exited.connect(_on_Area2D_animal_exited)

	var detection_radius = get_node("Area_Detection").get_node("Detection_Radius")
	detection_radius.shape.radius = genes.sense_range
