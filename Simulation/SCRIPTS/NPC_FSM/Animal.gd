extends Animal_Characteristics

class_name Animal

var genes: Animal_Genes = Animal_Genes.new()
var map_position: Vector2i
var animal_id: int = randi()
var vore_type : World.Vore_Type

func determine_genetic_distance(self_genes: Animal_Genes, other_genes: Animal_Genes) -> float:
    var similarity = 0.0
    similarity += (self_genes.size - other_genes.size)**2
    similarity += (self_genes.speed - other_genes.speed)**2
    similarity += 2*(self_genes.food_prefference - other_genes.food_prefference)**2
    similarity += (self_genes.mating_rate - other_genes.mating_rate)**2
    return sqrt(similarity)

func can_mate_genetically(other_genes: Animal_Genes) -> bool:
    var distance = determine_genetic_distance(self.genes, other_genes)
    var similarity = (1 - (distance / World.max_genetic_distance))
    return similarity > World.min_allowed_genetic_distance

func can_mate_animal(other: Animal) -> bool:
    if other.ready_to_mate != 1:
        return false
    return can_mate_genetically(other.genes)

func set_vore_type():
    if genes.food_prefference > 0.75:
        vore_type = World.Vore_Type.CARNIVORE
    elif genes.food_prefference < 0.25:
        vore_type = World.Vore_Type.HERBIVORE
    else:
        vore_type = World.Vore_Type.OMNIVORE

func spawn_animal(mother, father):
    genes.pass_down_genes(mother, father)
    set_characteristics(genes)
    set_vore_type() 

# func construct_animal():
#     genes.generate_genes()
#     set_characteristics(genes)
#     generation = 0 # NOTE: here animals are created to populate the initial world, so in effect they represent the 0th generation of randomly generated animals

func construct_predetermined_animal():
    var size = randf_range(0.47, 0.53)
    var speed = randf_range(0.47, 0.53)
    var food_prefference = randf_range(0.17, 0.23)
    var mating_rate = randf_range(0.27, 0.33)
    genes.set_genes(size, speed, food_prefference, mating_rate)
    set_characteristics(genes)
    generation = 0 # NOTE: here animals are created to populate the initial world, so in effect they represent the 0th generation of randomly generated animals
    set_vore_type() 

func resource_calc():
    nutrition -= food_consumption
    hydration -= water_consumption

func update_animal_resources():
    resource_calc()
    nutrition_norm = nutrition / max_resources
    hydration_norm = hydration / max_resources
    ready_to_mate += genes.mating_rate / 75.0
    ready_to_mate = min(ready_to_mate, 1)

func kill_animal():
    add_meat_to_tile(mass)
    World.animals.erase(animal_id) # NOTE: remove animal refference from the world
    World.Map.tiles[map_position].animal_ids.erase(animal_id) # NOTE: remove animal from the tile

func fight(defender: Animal) -> bool: 
    #TODO: add fight mechanism -> attacker wins means 
    var attack_roll = randf_range(0, genes.size + defender.genes.size)
    if attack_roll < genes.size:
        World.animal_deaths_predation += 1
        eat_animal(defender) # NOTE: right now attacking is only done when searching for meat
        return true
    else:
        return false # failed to kill the defender (pass turn) maybe add more consequences

func get_huntable_prey() -> Array:
    var prey = []
    for prey_id in World.Map.tiles[map_position].animal_ids:
        #NOTE: get animal_ids on current tile -> no need to check if animal still exists
        if prey_id not in World.animals:
            continue
        var animal = World.animals[prey_id]
        if animal != self && animal.genes.size < genes.size: # NOTE: placeholder, size is the only factor right now
            prey.append(animal)
    return prey

func get_random_huntable_prey() -> Animal:
    var prey = get_huntable_prey()
    if prey.size() > 0:
        return prey.pick_random()
    return null

func get_random_huntable_scent() -> Animal_Scent:
    var scents = World.Map.tiles[map_position].scent_trails
    var huntable_scents = []
    for scent in scents:
        if scent.animal_id not in World.animals:
            continue
        var animal = World.animals[scent.animal_id]
        if animal != self and animal.genes.size < genes.size:
            huntable_scents.append(scent)
    if huntable_scents.size() > 0:
        return huntable_scents.pick_random()
    return null

# func animal_hydrate(water_tile, delta: float):

# func select_mating_partner(potential_mates: Array[Animal]) -> Animal:

func eat_meat(meat_amount: float):
    var food_type_efficiency = genes.food_prefference ** 0.5

    var nutrition_needed = max_resources - nutrition # space in stomach for meat
    var nutrition_eaten = min(meat_amount, nutrition_needed) # how much we are allowed to eat

    var nutrition_gained = nutrition_eaten * food_type_efficiency # how much we actually gain from eating
    World.nutrition_from_meat += nutrition_gained
    nutrition += nutrition_gained 

    return nutrition_eaten
    # var nutrition_available = meat_amount * food_type_efficiency
    # var nutrition_needed = max_resources - nutrition
    # var nutrition_gained = min(nutrition_available, nutrition_needed)

    # nutrition += nutrition_gained
    # var meat_consumed = nutrition_gained / food_type_efficiency
    # return meat_consumed

func eat_animal(animal: Animal):
    var meat = animal.mass
    var meat_consumed = eat_meat(meat)
    add_meat_to_tile(meat - meat_consumed)
    animal.kill_animal()

func add_meat_to_tile(meat_amount: float):
    var tile = World.Map.tiles[map_position]
    if tile.meat_in_rounds.size() == 0 or tile.meat_in_rounds[-1].spoils_in != tile.meat_spoil_rate:
        var meat = Meat.new(meat_amount, tile.meat_spoil_rate)
        tile.meat_in_rounds.insert(0, meat)
    else:
        tile.meat_in_rounds[-1].amount += meat_amount
    tile.total_meat += meat_amount

func eat_meat_on_current_tile():
    var meat = World.Map.tiles[map_position].total_meat
    var meat_consumed = eat_meat(meat)
    add_meat_to_tile(meat - meat_consumed)


func carnivore_eat():
    var tile = World.Map.tiles[map_position]
    var meat = tile.total_meat
    if meat > 0:
        eat_meat_on_current_tile()
    else:
        var prey = get_random_huntable_prey()
        if prey != null:
            fight(prey) # fought an animal
        else:
            #NOTE: could add tracing of animal_scent here
            var prey_scent = get_random_huntable_scent()
            if prey_scent != null:
                move_to_tile(prey_scent.scent_direction)
                return # successfully moved to prey scent
            if vore_type == World.Vore_Type.OMNIVORE:
                var plant_matter = tile.plant_matter
                if plant_matter > 0:
                    eat_plant_matter_on_current_tile()
                    return # successfully ate plants
            move_random() # default behaviour if no prey_scent (carnivore) or plant_matter (omnivore) is available

func eat_plant_matter_on_current_tile():
    var plant_matter = World.Map.tiles[map_position].plant_matter
    var food_type_efficiency = (1 - genes.food_prefference) ** 0.5

    # var nutrition_available = plant_matter * food_type_efficiency
    # var nutrition_needed = max_resources - nutrition
    # var nutrition_gained = min(nutrition_available, nutrition_needed)

    var nutrition_needed = max_resources - nutrition # space in stomach for plant matter
    var nutrition_eaten = min(plant_matter, nutrition_needed) # how much we are allowed to eat
    World.Map.tiles[map_position].plant_matter -= nutrition_eaten

    var nutrition_gained = nutrition_eaten * food_type_efficiency # how much we actually gain from eating
    nutrition += nutrition_gained
    World.nutrition_from_plants += nutrition_gained

    # World.nutrition_from_plants += nutrition_gained

    # nutrition += nutrition_gained
    # World.Map.tiles[map_position].plant_matter -= nutrition_gained / food_type_efficiency

func herbivore_eat():
    var tile = World.Map.tiles[map_position]
    var plant_matter = tile.plant_matter
    if plant_matter > 0:
        eat_plant_matter_on_current_tile()
    else:
        if vore_type == World.Vore_Type.OMNIVORE:
            var meat = tile.total_meat
            if meat > 0:
                eat_meat_on_current_tile()
            else:
                var rand = randf_range(0, 1)
                if rand < genes.food_prefference:
                    var prey = get_random_huntable_prey()
                    if prey != null:
                        fight(prey)
                    # if not hunting, or no prey available, move randomly
        move_random()

func eat():
    if vore_type == World.Vore_Type.CARNIVORE:
        carnivore_eat()
    elif vore_type == World.Vore_Type.HERBIVORE:
        herbivore_eat()
    else:
        var rand = randf_range(0, 1)
        if rand < genes.food_prefference:
            carnivore_eat()
        else:
            herbivore_eat()

func drink():
    var tile = World.Map.tiles[map_position]
    var water = tile.hydration
    if water > 0:
        var water_needed = max_resources - hydration
        var water_gained = min(water, water_needed)
        hydration += water_gained
        World.Map.tiles[map_position].hydration -= water_gained
    else:
        move_random()

func get_potential_mates():
    var potential_mates = []
    for mate_id in World.Map.tiles[map_position].animal_ids:
        if mate_id not in World.animals:
            continue
        var animal = World.animals[mate_id]
        if animal != self and can_mate_animal(animal):
            # TODO: maybe add check to see if the animal is ready to mate aswell
            potential_mates.append(animal)
    return potential_mates

func get_potential_mate_scents():
    var potential_mate_scents = []
    for scent in World.Map.tiles[map_position].scent_trails:
        if scent.animal_id != animal_id and scent.animal_id not in World.animals:
            continue

        var animal = World.animals[scent.animal_id]
        if animal != self and can_mate_animal(animal):
            potential_mate_scents.append(scent)
    return potential_mate_scents

func mate():
    var potential_mate = get_potential_mates()
    if potential_mate.size() > 0:
        var selected_mate = potential_mate.pick_random()
        reproduce_with_animal(selected_mate)
        ready_to_mate = 0
        selected_mate.ready_to_mate = 0
    else:
        var potential_mate_scents = get_potential_mate_scents()
        if potential_mate_scents.size() > 0:
            var picked_scent = potential_mate_scents.pick_random()
            move_to_tile(picked_scent.scent_direction)
        else:
            move_random()

func move_to_tile(destination):
    var scent = Animal_Scent.new(destination, 10, animal_id)
    World.Map.tiles[map_position].scent_trails.append(scent) #NOTE: leave a scent trail

    World.Map.tiles[map_position].animal_ids.erase(animal_id) #NOTE: remove animal from current tile
    World.Map.tiles[destination].animal_ids.append(animal_id) #NOTE: add animal to destination tile

    map_position = destination #NOTE: move to a random neighbour

func move_random():
    var neighbours = World.get_neighbouring_tiles(map_position) #NOTE: get all neighbours for current tile
    var rand = randi_range(0, neighbours.size() - 1) #NOTE: includsive range so - 1

    var destination = neighbours[rand]
    move_to_tile(destination)

func reproduce_with_animal(animal: Animal):
    World.on_animal_birth_request(map_position, self.genes, animal.genes)

func animal_starved_of_resources():
    if nutrition <= 0:
        World.animal_deaths_starvation += 1
        return true
    if hydration <= 0:
        World.animal_deaths_dehydration += 1
        return true
    return false

func process_animal():
    if nutrition_norm < seek_nutrition_norm and nutrition_norm < hydration_norm:
        eat()
    elif hydration_norm < seek_hydration_norm:
        drink()
    elif ready_to_mate >= 1:
        mate()
    else:
        move_random()
        # do something - easy food, or drink, or move, etc.
    
    update_animal_resources()
    if animal_starved_of_resources():
        kill_animal()

    age += 1
    if age > life_span:
        World.animal_deaths_age += 1
        kill_animal()
