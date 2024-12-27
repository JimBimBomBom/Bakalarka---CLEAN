extends Animal_Characteristics

class_name Animal

var genes: Animal_Genes = Animal_Genes.new()
var map_position: Vector2i

func spawn_animal(mother, father):
    genes.pass_down_genes(mother, father)
    set_characteristics(genes)

func construct_animal():
    genes.generate_genes()
    set_characteristics(genes)
    generation = 0 # NOTE: here animals are created to populate the initial world, so in effect they represent the 0th generation of randomly generated animals

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

# a simple implementation of a fight
func fight(defender: Animal) -> void: 
    defender.kill_animal()

func get_huntable_prey() -> Array[Animal]:
    var prey = []
    for animal in World.animals:
        if animal != self && animal.genes.size < genes.size: # NOTE: placeholder, size is the only factor right now
            prey.append(animal)
    return prey

func get_random_huntable_prey() -> Animal:
    var prey = get_huntable_prey()
    if prey.size() > 0:
        return prey[randi() % prey.size()]
    return null

func hunt():
    var curr_tile = World.get_tile(map_position)
    var prey = get_random_huntable_prey() # NOTE: for now there is no selecting mechanism


# func animal_hydrate(water_tile, delta: float):

# func select_mating_partner(potential_mates: Array[Animal]) -> Animal:

func eat():
    var rand = randf_range(0, 1)
    if rand < genes.food_prefference:
        #carnivore eat
        pass
    else:
        #herbivore eat
        pass

# Random move to a neighbouring tile
func move():
    var new_position = map_position
    while new_position == map_position:
        var rand = randi_range(0, 6)

        if map_position.y % 2 == 0:
            if rand == 0 && position.x < World.width: # Right
                new_position.x += 1
            elif rand == 1 && position.y < World.height: # Down-Right
                new_position.y += 1
            elif rand == 2 && (position.x > 0 && position.y < World.height): # Down-Left
                new_position.x -= 1
                new_position.y += 1
            elif rand == 3 && position.x > 0: # Left
                new_position.x -= 1
            elif rand == 4 && (position.x > 0 && position.y > 0): # Up-Left
                new_position.x -= 1
                new_position.y -= 1
            elif rand == 5 && position.y > 0: # Up-Right
                new_position.y -= 1
        else:
            if rand == 0 && position.x < World.width: # Right
                new_position.x += 1
            elif rand == 1 && (position.x < World.width && position.y < World.height): # Down-Right
                new_position.x += 1
                new_position.y += 1
            elif rand == 2 && position.y < World.height: # Down-Left
                new_position.y += 1
            elif rand == 3 && position.x > 0: # Left
                new_position.x -= 1
            elif rand == 4 && position.y > 0: # Up-Left
                new_position.y -= 1
            elif rand == 5 && (position.x < World.width && position.y > 0): # Up-Right
                new_position.x += 1
                new_position.y -= 1

func reproduce_with_animal(animal: Animal):
    # can_have_sex = false
    energy -= World.reproduction_energy_cost*max_energy

    # animal.can_have_sex = false
    # animal.sex_cooldown_timer.active = true
    animal.energy -= World.reproduction_energy_cost*animal.max_energy

    spawn_animal(self, animal)
