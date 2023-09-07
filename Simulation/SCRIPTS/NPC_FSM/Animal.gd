extends Npc_Properties_Class

class_name Animal

enum Animal_Base_States {
	INIT,
	DEAD,
	SATED,
	HUNGRY,
	THIRSTY,
	FLEEING,
	SLEEPING,
}
enum Animal_Types {
	WOLF,
	DEER,
}

signal birth_request(pos, type, parent_1, parent_2)

var animal_state : Animal_Base_States = Animal_Base_States.INIT
var animal_type : Animal_Types 
var corpse_timer : float = 0
var detected_animals : Array[Animal] # right now every animal is detected
# could add animals_in_range to mean all animals within our Detection_Radius
# + detected_animals for animals that we are aware of being in our radius

func spawn_animal(pos_, type, parent_1, parent_2):
	set_basic_properties(pos_, parent_1, parent_2)
	set_animal_properties(type, parent_1, parent_2)

func construct_animal(pos_ : Vector2i, type : World.Vore_Type):
	var max_velocity_ = randf_range(0.5, 0.8)
	var max_steering_force_ = randf_range(0.1, 0.3)
	var curr_pos_ = Vector2(pos_.x, pos_.y) * World.tile_size
	var wander_radius_ = 30#randf_range(30, 60)
	var wander_offset_ = 100

	set_npc(curr_pos_, max_velocity_, max_steering_force_, wander_radius_, wander_offset_)
	properties_generator(type)

func kill_animal():
	animal_state = Animal_Base_States.DEAD
	remove_from_group(World.animal_group) 
	add_to_group(World.cadaver_group)
	stop_animal()

func set_base_state(dangerous_animals : Array[Animal]):
	if curr_hunger <= 0 or curr_hydration <= 0 or curr_health <= 0:
		kill_animal()
	elif not dangerous_animals.is_empty():
		animal_state = Animal_Base_States.FLEEING
	elif curr_hunger_norm < seek_nutrition_threshold and curr_hunger_norm < curr_hydration_norm:
		animal_state = Animal_Base_States.HUNGRY
	elif curr_hydration_norm < seek_hydration_threshold and curr_hydration_norm <= curr_hunger_norm:
		animal_state = Animal_Base_States.THIRSTY
	else:
		animal_state = Animal_Base_States.SATED

func stop_animal():
	curr_velocity *= 0
	acceleration *= 0

func process_cadaver(delta : float):
	corpse_timer += delta
	if corpse_timer >= corpse_max_timer or mass == 0:
		remove_from_group(World.cadaver_group)
		self.queue_free()

func update_animal_norms():
	curr_hunger_norm = curr_hunger/max_hunger
	curr_hydration_norm = curr_hydration/max_hydration

func can_see(pos) -> bool:
	if abs(curr_pos.distance_to(pos)) < sight_range and abs(curr_pos.angle_to(pos)) < field_of_view_half:
		return true
	return false

# func can_hear(pos) -> bool:
# 	if abs(curr_pos.distance_to(pos)) < hearing_range:
# 		return true
# 	return false

func get_animals_from_sight() -> Array[Animal]:
	# var animals = get_tree().get_nodes_in_group(World.animal_group)
	var result : Array[Animal]
	for animal in detected_animals:
		if can_see(animal.curr_pos):
			result.append(animal)
	return result

# func get_animals_from_hearing() -> Array[Animal]:
# 	# var animals = get_tree().get_nodes_in_group(World.animal_group)
# 	var result : Array[Animal]
# 	for animal in detected_animals:
# 		if can_hear(animal.curr_pos) and curr_pos != animal.curr_pos:
# 			result.append(animal)
# 	return result

func get_cadavers_from_smell() -> Array[Animal]:
	var result : Array[Animal]
	for animal in detected_animals:
		if animal.is_in_group(World.cadaver_group):#can hear.... TODO
			result.append(animal)
	return result

func filter_animals_by_danger(animals_in_range : Array[Animal]) -> Array[Animal]:
	var dangerous_animals : Array[Animal]
	for animal in animals_in_range:
		if vore_type == World.Vore_Type.HERBIVORE and animal.vore_type == World.Vore_Type.CARNIVORE:
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
	var closest_animal : float = curr_pos.distance_to(animals_of_same_type[0].curr_pos)
	for animal in animals_of_same_type:
		if animal.gender == World.Gender.FEMALE:
			var dist = curr_pos.distance_to(animal.curr_pos)
			if dist < closest_animal:
				result = animal
				closest_animal = dist
	return result

func get_flee_dir(animals : Array[Animal]) -> Vector2:
	var force : Vector2 = Vector2(0, 0)
	for animal in animals:
		var dist = abs(curr_pos.distance_to(animal.curr_pos))
		# var dir = curr_pos.direction_to(animal.curr_pos)
		var temp_force = evade(animal)
		force += temp_force/dist
	return force.normalized()

func get_separation_force(target: Animal):
	var dist = abs(curr_pos.distance_to(target.curr_pos))
	var dir = curr_pos.direction_to(target.curr_pos)
	return dir/dist

func get_cohesion_force(target: Animal):
	var dist = abs(curr_pos.distance_to(target.curr_pos))
	var dir = curr_pos.direction_to(target.curr_pos)
	return dir/dist

func get_alignment_force(target: Animal):
	return target.curr_velocity.normalized()

func get_flock_dir(animals: Array[Animal]) -> Vector2:
	var force : Vector2 = Vector2(0, 0)
	var separation_force : Vector2 = Vector2(0, 0)
	var cohesion_force : Vector2 = Vector2(0, 0)
	var alignment_force : Vector2 = Vector2(0, 0)
	for animal in animals:
		var dist = abs(curr_pos.distance_to(animal.curr_pos))
		if dist < separation_radius:
			separation_force -= get_separation_force(animal)
		if dist < cohesion_radius:
			cohesion_force += get_cohesion_force(animal)
		if dist < alignment_radius:
			alignment_force += get_alignment_force(animal)
	force = (separation_force.normalized() * separation_mult) + (cohesion_force.normalized() * cohesion_mult) + (alignment_force.normalized() * alignment_mult)
	return force.normalized()

func get_roam_dir(animals: Array[Animal]) -> Vector2:
	var force : Vector2 = wander()
	if not animals.is_empty():
		force += get_flock_dir(animals)
	return force
		
func fight(defender : Animal) -> void: # mb have a combat log -> combat instance with participants(many herbivores fighting off a carnivore etc.)
	defender.curr_health -= attack_damage
	if curr_pos.distance_to(defender.curr_pos) < defender.attack_range and randf_range(0, 1) < 0.2:
		curr_health -= defender.attack_damage

func drink_at_tile(tile : World.Tile_Properties, delta : float):
	curr_hydration += delta * (1/hearing_while_consuming)

func eat_at_tile(tile : World.Tile_Properties, delta : float):
	var food_gain = delta * (1/hearing_while_consuming)
	if tile.curr_food < food_gain:
		curr_hunger += tile.curr_food
		tile.curr_food = 0
		World.Map.set_tile_to_depleted_DEBUG(tile.index)
	else:
		tile.curr_food -= food_gain
		curr_hunger += food_gain

func within_bounds(tile_index : Vector2) -> bool:
	if tile_index.x > -World.width and tile_index.x < World.width and tile_index.y > -World.height and tile_index.y < World.height:
		return true
	return false

func max(a : int, b : int) -> int:
	if a > b:
		return a
	else:
		return b

func get_tiles_from_senses() -> Array[World.Tile_Properties]:
	var result : Array[World.Tile_Properties]
	var tiles_in_direction : int = max(1, sense_range / World.tile_size.x)
	var curr_tile_ind : Vector2i = curr_pos / World.tile_size

	var center_of_tile : Vector2i = World.tile_size/2
	var curr_tile_pos : Vector2i = curr_tile_ind * World.tile_size_i + center_of_tile
	for x in range(-tiles_in_direction, tiles_in_direction):
		for y in range(-tiles_in_direction, tiles_in_direction):
			var x_pos = curr_tile_pos.x + x*World.tile_size_i.x 
			var y_pos = curr_tile_pos.y + y*World.tile_size_i.y 
			var tile_index = curr_tile_ind + Vector2i(x, y)
			if within_bounds(tile_index) and curr_pos.distance_to(Vector2(x_pos, y_pos)) < sense_range:
				result.append(World.Map.tiles[tile_index])
	return result

func food_in_range() -> Array[World.Tile_Properties]:
	var result : Array[World.Tile_Properties]
	var tiles = get_tiles_from_senses()
	for tile in tiles:
		if tile.type == World.Tile_Type.PLAIN and tile.curr_food > 0: 
			result.append(tile)
	return result

func hydration_in_range() -> Array[World.Tile_Properties]:
	var result : Array[World.Tile_Properties]
	var tiles = get_tiles_from_senses()
	for tile in tiles:
		if tile.type == World.Tile_Type.WATER: 
			result.append(tile)
	return result

func select_food_tile(tiles: Array[World.Tile_Properties]) -> World.Tile_Properties:
	var result : World.Tile_Properties = tiles[0] # tiles is not empty if we are in this function
	for tile in tiles:
		var tmp : World.Tile_Properties = tile
		if curr_pos.distance_to(World.get_tile_pos(tmp)) < curr_pos.distance_to(World.get_tile_pos(result)):
			result = tmp
	return result

func select_hydration_tile(tiles: Array[World.Tile_Properties]) -> World.Tile_Properties:
	var result : World.Tile_Properties = tiles[0] # tiles is not empty if we are in this function
	for tile in tiles:
		var tmp : World.Tile_Properties = tile
		if curr_pos.distance_to(World.get_tile_pos(tmp)) < curr_pos.distance_to(World.get_tile_pos(result)):
			result = tmp
	return result

func select_potential_mates() -> Array[Animal]:
	var result : Array[Animal]
	for animal in detected_animals:
		if animal.gender == World.Gender.FEMALE and not animal.is_pregnant:
			result.append(animal)
	return result

func reproduce_with_animal(animal):
	reproduced_recently = true
	animal.become_pregnant(self)

func become_pregnant(partner):
	is_pregnant = true
	sexual_partner = partner
	get_node("pregnancy_timer").start()

func _on_pregnancy_timer_timeout():
	is_pregnant = false
	#emit_signal("birth_request", self, sexual_partner)
	birth_request.emit(curr_pos, vore_type, self, sexual_partner)
	sexual_partner = null

#Node component functions:
func _on_timer_timeout():
	pass # this func gets defined in instances of Carnivore/Herbivore

func _on_Area2D_animal_entered(body):
	if body is Animal and body.curr_pos != curr_pos:
		detected_animals.append(body)

func _on_Area2D_animal_exited(body):
	if body is Animal:
		detected_animals.erase(body)

func _ready():
	var timer = get_node("Timer") #?? mb add timeout for actions as a animal variable? could be interesting
	timer.timeout.connect(_on_timer_timeout)

	if gender == World.Gender.FEMALE:
		var pregnancy_timer = Timer.new()
		pregnancy_timer.set_name("pregnancy_timer")
		pregnancy_timer.set_wait_time(pregnancy_period)
		pregnancy_timer.set_one_shot(true)
		pregnancy_timer.timeout.connect(_on_pregnancy_timer_timeout)
		add_child(pregnancy_timer)
	
	var animal_detector = get_node("Area_Detection")
	animal_detector.body_entered.connect(_on_Area2D_animal_entered)
	animal_detector.body_exited.connect(_on_Area2D_animal_exited)

	var detection_radius = get_node("Area_Detection").get_node("Detection_Radius")
	detection_radius.shape.radius = max_hearing_range #hardset for now
