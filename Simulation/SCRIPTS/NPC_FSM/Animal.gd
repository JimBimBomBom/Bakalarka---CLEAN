# # extends Animal_Characteristics

# class_name Animal


# # NOTE: beginning of animal characteristics

# # tracking data
# var generation: int

# #Base stats
# var mass: float
# var base_activity_level: float

# var activity_level : float
# var base_metabolic_rate : float

# var normaliser : float = 200.0 # adjust to make life for animals possible

# var metabolic_rate : float

# var diet_modifier : float # gaining energy from meat is easier than from plants, etc.

# var food_consumption : float
# var water_consumption : float

# var ready_to_mate : float #NOTE: incremented by mating_rate, when it reaches 1, the animal is ready to mate

# var age : int
# var life_span : int

# var turns_to_change_tile : int # NOTE: how many turns does it take for the animal to change its position

# var max_resources : float

# var nutrition: float
# var nutrition_norm: float
# var seek_nutrition_norm: float = 0.3

# var hydration: float
# var hydration_norm: float
# var seek_hydration_norm: float = 0.3

# func get_diet_modifier(food_prefference) -> float:
#     # maybe add more modifiers here
#     return 1 + food_prefference ** 1.5 # pure carnivores have a 2x modifier, pure herbivores have a 1x modifier

# func get_turns_to_change_tile() -> int: 
#     if genes.speed < 0.33:
#         return 2
#     elif genes.speed < 0.66:
#         return 1
#     else:
#         return 0

# func set_characteristics():
#     age = 0
#     life_span = ((genes.size * 2) ** 2) * 400 + 250

#     mass = genes.size
#     turns_to_change_tile = get_turns_to_change_tile()

#     # TODO: add more factors here
#     base_activity_level = genes.speed ** 1.3 + genes.mating_rate ** 0.5 + genes.stealth ** 0.6 + genes.detection ** 0.9
#     base_metabolic_rate = mass ** 0.75 # Kleiber's Law
#     metabolic_rate = float(base_metabolic_rate * base_activity_level) / normaliser

#     diet_modifier = get_diet_modifier(genes.food_prefference)
#     food_consumption = metabolic_rate / diet_modifier
#     water_consumption = food_consumption * 3

#     max_resources = (mass ** 1.5) / 2

#     nutrition = 0.5 * max_resources
#     hydration = 0.5 * max_resources

#     ready_to_mate = 0 

# # NOTE : end of animal characteristics

# enum Vore_Type {
#     CARNIVORE,
#     HERBIVORE,
#     OMNIVORE,
# }

# var genes: Animal_Genes = Animal_Genes.new()
# var map_position: Vector2i
# var animal_id: int = randi()
# var vore_type : Vore_Type

# var moving_to_tile_turns_remaining: int = 0
# var is_moving: bool = false
# var destination : Vector2i

# func set_vore_type():
#     if genes.food_prefference > 0.75:
#         vore_type = Vore_Type.CARNIVORE
#     elif genes.food_prefference < 0.25:
#         vore_type = Vore_Type.HERBIVORE
#     else:
#         vore_type = Vore_Type.OMNIVORE

# func set_animal_to_world(animal, index):
#     animal.map_position = index
#     World.Map.tiles[index].animal_ids.append(animal.animal_id)

# func spawn_animal(mother, father):
#     genes.pass_down_genes(mother, father)
#     set_characteristics()
#     set_vore_type() 

# func construct_predetermined_animal(index):
#     var animal = Animal.new()
#     animal.construct_predetermined_animal_genes()
#     set_animal_to_world(animal, index)
#     World.animals[animal.animal_id] = animal

# func construct_predetermined_animal_genes():
#     var size = randf_range(0.47, 0.53)
#     var speed = randf_range(0.47, 0.53)
#     var food_prefference = randf_range(0.17, 0.23)
#     var mating_rate = randf_range(0.27, 0.33)
#     var stealth = randf_range(0.17, 0.23)
#     var detection = randf_range(0.17, 0.23)

#     genes.set_genes(size, speed, food_prefference, mating_rate, stealth, detection)
#     set_characteristics()
#     generation = 0 # NOTE: here animals are created to populate the initial world, so in effect they represent the 0th generation of randomly generated animals
#     set_vore_type() 

# func reproduce_with_animal(partner: Animal):
#     var child = Animal.new()
#     spawn_animal(self, partner)
#     set_animal_to_world(child, map_position)

# func resource_calc():
#     nutrition -= food_consumption
#     hydration -= water_consumption

# func update_animal_resources():
#     resource_calc()
#     nutrition_norm = nutrition / max_resources
#     hydration_norm = hydration / max_resources
#     ready_to_mate += genes.mating_rate / 125.0
#     ready_to_mate = min(ready_to_mate, 1)

# func remove_animal_from_world():
#     World.animals.erase(animal_id) # NOTE: remove animal refference from the world
#     World.Map.tiles[map_position].animal_ids.erase(animal_id) # NOTE: remove animal from the tile

# func kill_animal():
#     var meat_amount = mass * 0.5 # NOTE: placeholder
#     add_meat_to_tile(meat_amount)
#     remove_animal_from_world()

# func fight(defender: Animal) -> bool: 
#     var attacker_power = genes.size * (genes.food_prefference ** 0.5)
#     var defender_power = defender.genes.size * (defender.genes.food_prefference ** 0.5)

#     var stealth_roll =  randf_range(0, genes.stealth + defender.genes.detection)
#     if stealth_roll < genes.stealth: # attacker was not detected
#         attacker_power *= 2 # stealth bonus
#     elif stealth_roll < defender.genes.detection: # attacker was detected -> prey tries to run away
#         var speed_roll = randf_range(0, genes.speed ** 2 + defender.genes.speed ** 2)
#         if speed_roll > genes.speed ** 2: # prey got away
#             return false

#     var attack_roll = randf_range(0, attacker_power + defender_power)
#     if attack_roll < attacker_power: # attacker wins
#         # World.animal_deaths_predation += 1
#         kill_animal()
#         return true
#     else: # defender wins
#         nutrition -= 0.05 * max_resources # NOTE: placeholder for consequences of losing a fight
#         return false

# func get_huntable_prey() -> Array:
#     var prey = []
#     for prey_id in World.Map.tiles[map_position].animal_ids:
#         #NOTE: get animal_ids on current tile -> no need to check if animal still exists
#         # if prey_id not in World.animals or prey_id == animal_id:
#         if prey_id == animal_id:
#             continue
#         if prey_id not in World.animals:
#             print("ERROR: animal_id not in World.animals")
#         var animal = World.animals[prey_id]
#         var detection_roll = randf_range(0, genes.detection + animal.genes.stealth)
#         if detection_roll < genes.detection: # we detected the prey
#             prey.append(animal)
#     return prey

# func get_random_huntable_prey() -> Animal:
#     var prey = get_huntable_prey()
#     if prey.size() > 0:
#         return prey.pick_random()
#     return null

# func get_random_huntable_scent() -> Animal_Scent:
#     var scents = World.Map.tiles[map_position].scent_trails
#     var huntable_scents = []
#     for scent in scents:
#         if scent.animal_id not in World.animals: # animal is dead
#             continue
#         var animal = World.animals[scent.animal_id]
#         if animal != self and animal.genes.size < genes.size:
#             huntable_scents.append(scent)
#     if huntable_scents.size() > 0:
#         return huntable_scents.pick_random()
#     return null

# func remove_meat_from_tile(meat_ammount: float):
#     var tile = World.Map.tiles[map_position]
#     while meat_ammount > 0:
#         if tile.meat_in_rounds.size() == 0:
#             break

#         var meat = tile.meat_in_rounds[-1]
#         if meat.amount <= meat_ammount:
#             meat_ammount -= meat.amount
#             tile.meat_in_rounds.pop_back()
#         else:
#             meat.amount -= meat_ammount
#             break
#     tile.total_meat -= meat_ammount

# func add_meat_to_tile(meat_amount: float):
#     var tile = World.Map.tiles[map_position]
#     if tile.meat_in_rounds.size() == 0 or tile.meat_in_rounds[-1].spoils_in != tile.meat_spoil_rate:
#         var meat = Meat.new(meat_amount, tile.meat_spoil_rate)
#         tile.meat_in_rounds.insert(0, meat)
#     else:
#         tile.meat_in_rounds[-1].amount += meat_amount
#     tile.total_meat += meat_amount

# func eat_meat():
#     var meat_amount = World.Map.tiles[map_position].total_meat
#     var food_type_efficiency = genes.food_prefference ** 0.5

#     var nutrition_needed = max_resources - nutrition # space in stomach for meat
#     var nutrition_eaten = min(meat_amount, nutrition_needed) # how much we are allowed to eat

#     var nutrition_gained = nutrition_eaten * food_type_efficiency # how much we actually gain from eating
#     # World.nutrition_from_meat += nutrition_gained
#     nutrition += nutrition_gained 

#     return nutrition_eaten

# func eat_meat_on_current_tile():
#     var meat_consumed = eat_meat()
#     remove_meat_from_tile(meat_consumed)

# func eat_plant_matter_on_current_tile():
#     var plant_matter = World.Map.tiles[map_position].plant_matter
#     var food_type_efficiency = (1 - genes.food_prefference) ** 0.5

#     var nutrition_needed = max_resources - nutrition # space in stomach for plant matter
#     var nutrition_eaten = min(plant_matter, nutrition_needed) # how much we are allowed to eat
#     World.Map.tiles[map_position].plant_matter -= nutrition_eaten

#     var nutrition_gained = nutrition_eaten * food_type_efficiency # how much we actually gain from eating
#     nutrition += nutrition_gained
#     # World.nutrition_from_plants += nutrition_gained

# func carnivore_eat():
#     var tile = World.Map.tiles[map_position]
#     var meat = tile.total_meat
#     if meat > 0:
#         eat_meat_on_current_tile()
#     else:
#         var prey = get_random_huntable_prey()
#         if prey != null:
#             var won = fight(prey) # fought an animal
#             if won:
#                 eat_meat_on_current_tile() # eat animal
#             else:
#                 pass # NOTE: failed to kill the prey, maybe add more consequences
#         else:
#             #NOTE: could add tracing of animal_scent here
#             var prey_scent = get_random_huntable_scent()
#             if prey_scent != null:
#                 begin_move_to_tile(prey_scent.scent_direction)
#                 return # successfully moved to prey scent
#             if vore_type == Vore_Type.OMNIVORE:
#                 var plant_matter = tile.plant_matter
#                 if plant_matter > 0:
#                     eat_plant_matter_on_current_tile()
#                     return # successfully ate plants
#             move_random() # default behaviour if no prey_scent (carnivore) or plant_matter (omnivore) is available

# func herbivore_eat():
#     var tile = World.Map.tiles[map_position]
#     var plant_matter = tile.plant_matter
#     if plant_matter > 0:
#         eat_plant_matter_on_current_tile()
#     else:
#         if vore_type == Vore_Type.OMNIVORE:
#             var meat = tile.total_meat
#             if meat > 0:
#                 eat_meat_on_current_tile()
#             else:
#                 var rand = randf_range(0, 1)
#                 if rand < genes.food_prefference:
#                     var prey = get_random_huntable_prey()
#                     if prey != null:
#                         var won = fight(prey)
#                         if won:
#                             eat_meat_on_current_tile()
#                         else:
#                             pass # NOTE: failed to kill the prey, maybe add more consequences
#                     # if not hunting, or no prey available, move randomly
#         move_random()

# func eat():
#     if vore_type == Vore_Type.CARNIVORE:
#         carnivore_eat()
#     elif vore_type == Vore_Type.HERBIVORE:
#         herbivore_eat()
#     else:
#         var rand = randf_range(0, 1)
#         if rand < genes.food_prefference:
#             carnivore_eat()
#         else:
#             herbivore_eat()

# func drink():
#     var tile = World.Map.tiles[map_position]
#     var water = tile.hydration
#     if water > 0:
#         var water_needed = max_resources - hydration
#         var water_gained = min(water, water_needed)
#         hydration += water_gained
#         World.Map.tiles[map_position].hydration -= water_gained
#     else:
#         move_random()

# func determine_genetic_distance(self_genes: Animal_Genes, other_genes: Animal_Genes) -> float:
#     var similarity = 0.0
#     similarity += (self_genes.size - other_genes.size)**2
#     similarity += (self_genes.speed - other_genes.speed)**2
#     similarity += (3*(self_genes.food_prefference - other_genes.food_prefference))**2
#     similarity += (self_genes.mating_rate - other_genes.mating_rate)**2
#     similarity += (self_genes.stealth - other_genes.stealth)**2
#     similarity += (self_genes.detection - other_genes.detection)**2
#     return sqrt(similarity)


# func can_mate_genetically(other_genes: Animal_Genes) -> bool:
#     var distance = determine_genetic_distance(self.genes, other_genes)
#     var similarity = (1 - (distance / World.max_genetic_distance))
#     return similarity > World.min_allowed_genetic_distance

# func can_mate_animal(other: Animal) -> bool:
#     if other.ready_to_mate != 1:
#         return false
#     return can_mate_genetically(other.genes)

# func get_potential_mates():
#     var potential_mates = []
#     for mate_id in World.Map.tiles[map_position].animal_ids:
#         if mate_id not in World.animals:
#             continue
#         var animal = World.animals[mate_id]
#         if animal != self and can_mate_animal(animal):
#             # TODO: maybe add check to see if the animal is ready to mate aswell
#             potential_mates.append(animal)
#     return potential_mates

# func get_potential_mate_scents():
#     var potential_mate_scents = []
#     for scent in World.Map.tiles[map_position].scent_trails:
#         if scent.animal_id != animal_id and scent.animal_id not in World.animals:
#             continue

#         var animal = World.animals[scent.animal_id]
#         if animal != self and can_mate_animal(animal):
#             potential_mate_scents.append(scent)
#     return potential_mate_scents

# func mate():
#     var potential_mate = get_potential_mates()
#     if potential_mate.size() > 0:
#         var selected_mate = potential_mate.pick_random()
#         reproduce_with_animal(selected_mate)
#         ready_to_mate = 0
#         selected_mate.ready_to_mate = 0
#     else:
#         # NOTE: since we are tracking a specific scent, if we do not find a mate on our next tile, we could still follow this scent
#         var potential_mate_scents = get_potential_mate_scents()
#         if potential_mate_scents.size() > 0:
#             var mate_scent = potential_mate_scents.pick_random()
#             begin_move_to_tile(mate_scent.scent_direction)
#         else:
#             move_random()

# # TODO: animals that are moving should be processed last -> iterate over the animals twice, once for overall processing, another for moving
# func perform_move():
#     if moving_to_tile_turns_remaining > 0:
#         moving_to_tile_turns_remaining -= 1
#         return
#     else:
#         var scent = Animal_Scent.new(destination, World.scent_duration, animal_id)
#         World.Map.tiles[map_position].scent_trails.append(scent) #NOTE: leave a scent trail

#         World.Map.tiles[map_position].animal_ids.erase(animal_id) #NOTE: remove animal from previous tile
#         World.Map.tiles[destination].animal_ids.append(animal_id) #NOTE: add animal to destination tile

#         is_moving = false
#         map_position = destination

# func begin_move_to_tile(move_destination):
#     moving_to_tile_turns_remaining = turns_to_change_tile
#     is_moving = true
#     destination = move_destination

#     # perform_move() # NOTE: this should be called in the main loop, not here

# func move_random():
#     var neighbours = get_neighbouring_tiles(map_position) #NOTE: get all neighbours for current tile
#     var rand = randi_range(0, neighbours.size() - 1) #NOTE: includsive range so - 1

#     var move_destination = neighbours[rand]
#     begin_move_to_tile(move_destination)


# func animal_starved_of_resources():
#     if nutrition <= 0:
#         # World.animal_deaths_starvation += 1
#         return true
#     if hydration <= 0:
#         # World.animal_deaths_dehydration += 1
#         return true
#     return false

# func process_animal():
#     # if is_moving:
#     #     perform_move()
#     #     return
#     # NOTE: this should be called in the main loop, not here

#     if nutrition_norm < seek_nutrition_norm and nutrition_norm < hydration_norm:
#         eat()
#     elif hydration_norm < seek_hydration_norm:
#         drink()
#     elif ready_to_mate >= 1:
#         mate()
#     else:
#         move_random() # NOTE: could add some characteristic that will mean that animals are reluctant to move
#         # do something - easy food, or drink, or move, etc.
    
#     update_animal_resources()
#     if animal_starved_of_resources():
#         kill_animal()

#     age += 1
#     if age > life_span:
#         # World.animal_deaths_age += 1
#         kill_animal()

# # NOTE: helper functions
# ############################################################################################
# func between(val, start, end):
#     if start <= val and val <= end:
#         return true
#     return false

# func axial_distance_inline(a, b):
#     return (abs(a.x - b.x) + abs(a.x + a.y - b.x - b.y) + abs(a.y - b.y)) / 2

# func offset_to_axial(pos):
#     var q = pos.x - (pos.y - (pos.y&1)) / 2
#     var r = pos.y
#     return Vector2i(q, r)

# func axial_to_offset(pos):
#     var x = pos.x + (pos.y - (pos.y&1)) / 2
#     var y = pos.y
#     return Vector2i(x, y)

# func offset_distance(a, b):
#     var ac = offset_to_axial(a)
#     var bc = offset_to_axial(b)
#     return axial_distance_inline(ac, bc)

# func get_neighbouring_tiles_in_range(tile_pos : Vector2i, tile_range : int) -> Array[Vector2i]:
#     var neighbours : Array[Vector2i] = []
#     for x in range(-tile_range, tile_range + 1):
#         for y in range(-tile_range, tile_range + 1):
#             var pos = Vector2i(tile_pos.x + x, tile_pos.y + y)
#             if between(pos.x, 0, World.sim_params.width - 1) and between(pos.y, 0, World.sim_params.height - 1) and offset_distance(tile_pos, pos) <= tile_range:
#                 neighbours.append(pos)
#     neighbours.erase(tile_pos) # NOTE: remove the current tile from the list of neighbours
#     return neighbours

# func get_neighbouring_tiles(tile_pos: Vector2i):
#     return get_neighbouring_tiles_in_range(tile_pos, 1)
