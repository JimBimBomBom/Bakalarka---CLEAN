# class_name Animal_Characteristics

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

# func get_turns_to_change_tile(genes) -> int: 
#     if genes.speed < 0.33:
#         return 2
#     elif genes.speed < 0.66:
#         return 1
#     else:
#         return 0

# func set_characteristics(genes: Animal_Genes):
#     age = 0
#     life_span = ((genes.size * 2) ** 2) * 400 + 250

#     mass = genes.size
#     turns_to_change_tile = get_turns_to_change_tile(genes)

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
