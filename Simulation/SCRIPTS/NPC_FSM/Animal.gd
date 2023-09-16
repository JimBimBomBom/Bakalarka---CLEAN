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
enum Animal_Types {
	WOLF,
	DEER,
}

signal birth_request(pos, type, parent_1, parent_2)

var animal_state : Animal_Base_States = Animal_Base_States.INIT

var genes : Animal_Genes
var animal_type : Animal_Types 
var detected_animals : Array[Animal] = [] # right now every animal is detected
# could add animals_in_range to mean all animals within our Detection_Radius
# + detected_animals for animals that we are aware of being in our radius

func spawn_animal(pos, type, parent_1, parent_2):
	genes.pass_down_genes(parent_1.genes, parent_2.genes)
	set_characteristics(genes)
	position = Vector2(pos.x, pos.y) * World.tile_size

func construct_animal(pos : Vector2i, type : World.Vore_Type):
	genes.generate_genes()
	set_characteristics(genes)
	position = Vector2(pos.x, pos.y) * World.tile_size

func kill_animal():
	animal_state = Animal_Base_States.DEAD
	stop_animal()
	remove_from_group(World.animal_group) 
	add_to_group(World.cadaver_group)
	var timer = get_node("Timer") # hijack decision timer + set its' wait_time
	timer.wait_time = World.corpse_timer
	timer.stop()
	timer.start()

func set_base_state(dangerous_animals : Array[Animal]):
	if hunger <= 0 or hydration <= 0 or health <= 0:
		kill_animal()
	elif not dangerous_animals.is_empty():
		animal_state = Animal_Base_States.FLEEING
	elif hunger_norm < World.seek_nutrition_threshold and hunger_norm < hydration_norm:
		animal_state = Animal_Base_States.HUNGRY
	elif hydration_norm < World.seek_hydration_threshold:
		animal_state = Animal_Base_States.THIRSTY
	else:
		animal_state = Animal_Base_States.SATED

func stop_animal():
	velocity *= 0
	acceleration *= 0

func free_cadaver():
	remove_from_group(World.cadaver_group)
	self.queue_free()

func update_animal_norms():
	hunger_norm = hunger/max_resources
	hydration_norm = hydration/max_resources

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
		if genes.vore_type == World.Vore_Type.HERBIVORE and animal.genes.vore_type == World.Vore_Type.CARNIVORE:
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

func get_flee_dir(animals : Array[Animal]) -> Vector2:
	var force : Vector2 = Vector2(0, 0)
	for animal in animals:
		var dist = abs(position.distance_to(animal.position))
		var temp_force = evade(animal)
		force += temp_force/dist
	return force.normalized()

func get_separation_force(target: Animal):
	var dist = abs(position.distance_to(target.position))
	var dir = position.direction_to(target.position)
	return dir/dist

func get_cohesion_force(target: Animal):
	var dist = abs(position.distance_to(target.position))
	var dir = position.direction_to(target.position)
	return dir/dist

func get_alignment_force(target: Animal):
	return target.curr_velocity.normalized()

func get_flock_dir(animals: Array[Animal]) -> Vector2:
	var force : Vector2 = Vector2(0, 0)
	var separation_force : Vector2 = Vector2(0, 0)
	var cohesion_force : Vector2 = Vector2(0, 0)
	var alignment_force : Vector2 = Vector2(0, 0)
	for animal in animals:
		var dist = abs(position.distance_to(animal.position))
		if dist < separation_radius:
			separation_force -= get_separation_force(animal)
		if dist < cohesion_radius:
			cohesion_force += get_cohesion_force(animal)
		if dist < alignment_radius:
			alignment_force += get_alignment_force(animal)
	force = (separation_force.normalized() * genes.separation_mult) + (cohesion_force.normalized() * genes.cohesion_mult) + (alignment_force.normalized() * genes.alignment_mult)
	return force.normalized()

func get_roam_dir(animals: Array[Animal]) -> Vector2: # BIG TODOOOOOO
	# var force : Vector2 = wander()
	var force = Vector2(0, 0)
	if not animals.is_empty():
		force += get_flock_dir(animals)
	return force
		
func fight(defender : Animal) -> void: # mb have a combat log -> combat instance with participants(many herbivores fighting off a carnivore etc.)
	defender.health -= attack_damage
	if position.distance_to(defender.position) < defender.attack_range and randf_range(0, 1) < 0.2:
		health -= defender.attack_damage

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

func drink_at_tile(delta : float):#, tile : World.Tile_Properties):
	hydration += delta

func select_potential_mates() -> Array[Animal]:
	var result : Array[Animal]
	for animal in detected_animals:
		if animal.gender == World.Gender.FEMALE and not animal.is_pregnant:
			result.append(animal)
	return result

func reproduce_with_animal(animal):
	# can_have_sex = false
	animal.become_pregnant(self)

func become_pregnant(partner):
	can_have_sex = false
	sexual_partner = partner
	get_node("pregnancy_timer").start()

#Node component functions:
func _on_pregnancy_timer_timeout():
	for i in range(0, genes.num_of_offspring):
		birth_request.emit(position, genes.vore_type, self, sexual_partner)
	can_have_sex = true
	sexual_partner = null

func _on_timer_timeout():
	pass # this func gets defined in instances of Carnivore/Herbivore

func _on_Area2D_animal_entered(body):
	if body is Animal and body.position != position:
		detected_animals.append(body)

func _on_Area2D_animal_exited(body):
	if body is Animal:
		detected_animals.erase(body)

func _ready():
	var timer = get_node("Timer") #?? mb add timeout for actions as an animal variable? could be interesting
	timer.timeout.connect(_on_timer_timeout)

	var sex_timer = Timer.new()
	if genes.gender == World.Gender.FEMALE: # TODO else to set male_sex_cooldown if wanted
		sex_timer.set_name("pregnancy_timer")
		sex_timer.set_wait_time(genes.pregnancy_duration)
		sex_timer.set_one_shot(true)
		sex_timer.timeout.connect(_on_pregnancy_timer_timeout)
		add_child(sex_timer)
	
	var animal_detector = get_node("Area_Detection")
	animal_detector.body_entered.connect(_on_Area2D_animal_entered)
	animal_detector.body_exited.connect(_on_Area2D_animal_exited)

	var detection_radius = get_node("Area_Detection").get_node("Detection_Radius")
	detection_radius.shape.radius = genes.sense_range
