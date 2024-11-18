extends Animal_Characteristics

class_name Animal

enum Animal_Base_States {
    #Universal states
    DEAD,
    SATED,
    THIRSTY,

    #Carnivore exclusive states
    EATING, # eating a cadaver
    HUNTING, # hunting a prey

    #Herbivore exclusive states
    HUNGRY,
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

var change_age_timer: SimulationTimer
var sex_cooldown_timer: SimulationTimer
var cadaver_timer: SimulationTimer
var update_animal_resources_timer: SimulationTimer
var execute_fsm_timer: SimulationTimer

var animal_state: Animal_Base_States = Animal_Base_States.SATED
var consumption_state: Consumption_State = Consumption_State.SEEKING

var genes: Animal_Genes = Animal_Genes.new()
var animal_type: Animal_Types
var detected_animals: Array[Animal] = [] # right now every animal is detected
var last_visited_water_tile: World.Tile_Properties
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

func free_cadaver():
    queue_free()

func kill_animal():
    animal_state = Animal_Base_States.DEAD
    cadaver_timer.active = true
    stop_animal()
    find_child("Area_Detection").monitoring = false
    if vore_type == World.Vore_Type.CARNIVORE:
        World.carnivore_count -= 1
    else:
        World.herbivore_count -= 1
    print("Carnivores: ", World.carnivore_count, " Herbivores: ", World.herbivore_count)

# should handle "consumption state"(which is also a bad name), where the base state "resets"
# every other state not affiliated with our current base state -> HUNGRY sets drinking_state to SEEKING and vice versa

func stop_animal():
    velocity *= 0.01
    desired_velocity *= 0.01

# NOTE : no need for delta, as the function is called by a timer -> delta could be removed, and World var be used directly instead
func resource_calc(delta: float):
    var energy_gain = metabolic_rate * delta
    var curr_energy_drain = energy_drain * delta # * energy_state (high_energy, low_energy, conservation_of_energy, etc.)
    if nutrition > metabolic_rate:
        nutrition -= metabolic_rate
    else:
        energy_gain = nutrition * delta
        nutrition = 0
    
    var curr_water_loss = water_loss * delta
    if hydration > curr_water_loss:
        hydration -= curr_water_loss
    else:
        hydration = 0
        # TODO : add consequences for not having any water
        energy_gain *= 0.6 # NOTE : placeholder
    
    energy += (energy_gain - curr_energy_drain)

func update_animal_resources(delta : float):
    resource_calc(delta)
    energy_norm = energy / max_energy
    nutrition_norm = nutrition / max_resources
    hydration_norm = hydration / max_resources

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

func get_cadavers() -> Array[Animal]:
    var result: Array[Animal]
    for animal in detected_animals:
        if animal.animal_state == Animal_Base_States.DEAD:
            result.append(animal)
    return result

# TODO: make everyone using this function use filter_animals_by_type instead
func filter_animals_by_danger() -> Array[Animal]:
    var dangerous_animals: Array[Animal]
    for animal in detected_animals:
        if animal.animal_state != Animal_Base_States.DEAD and vore_type == World.Vore_Type.HERBIVORE and animal.vore_type == World.Vore_Type.CARNIVORE:
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
        
func fight(defender: Animal) -> void: 
    defender.kill_animal()

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
    hydration += delta * 5 # NOTE: add some world variable to manage this
    #NOTE: drinking less per tick, means animals spend more time exposed etc.

func animal_hydrate(water_tile, delta: float):
    match consumption_state:
        Consumption_State.SEEKING:
            var target = World.get_tile_pos(water_tile)
            set_next_move(seek(target))
            if position.distance_to(target) < 10:
                consumption_state = Consumption_State.CONSUMING
        Consumption_State.CONSUMING:
            if position.distance_to(World.get_tile_pos(water_tile)) >= 10:
                consumption_state = Consumption_State.SEEKING
            else:
                stop_animal()
                last_visited_water_tile = water_tile
                drink_at_tile(delta) # TODO reason for animal to change into scanning, can be a timer
                if hydration_norm >= 1: 
                    consumption_state = Consumption_State.SEEKING

func select_potential_mates(animals: Array[Animal], animal_type: Animal_Types) -> Array[Animal]:
    var result: Array[Animal]
    var animals_of_same_type = filter_animals_by_type(animals, animal_type)
    for animal in animals_of_same_type:
        if animal.can_have_sex and animal.animal_state == Animal_Base_States.SATED and animal.energy_norm >= World.reproduction_energy_cost:
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
    energy -= World.reproduction_energy_cost*max_energy

    animal.can_have_sex = false
    animal.sex_cooldown_timer.active = true
    animal.energy -= World.reproduction_energy_cost*animal.max_energy

    birth_request.emit(position, vore_type, self, animal)

#Node component functions:

func _on_Area2D_animal_entered(body):
    if body is Animal and body.position != position:
        detected_animals.append(body)

func _on_Area2D_animal_exited(body):
    if body is Animal:
        detected_animals.erase(body)

func _on_change_age_timer_timeout():
    if age == World.Age_Group.OLD:
        # pass
        kill_animal()
    else:
        age += 1

func _on_sex_cooldown_timeout():
    can_have_sex = true

func do_timers(delta: float):
    if cadaver_timer.active:
        cadaver_timer.do_timer(delta)
        return
    change_age_timer.do_timer(delta) 
    if sex_cooldown_timer.active:
        sex_cooldown_timer.do_timer(delta, true)
