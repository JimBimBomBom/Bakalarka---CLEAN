class_name Animal_Characteristics

# tracking data
var generation: int

#Base stats
var mass: float
var base_activity_level: float

var activity_level : float
var base_metabolic_rate : float

var normaliser : float = 35.0 # adjust to make life for animals possible

var metabolic_rate : float

var diet_modifier : float # gaining energy from meat is easier than from plants, etc.

var food_consumption : float
var water_consumption : float

# var fat_storage: float
# var desired_fat_storage: float  # animals will not try to eat more if they were to have more fat storage than this value

var ready_to_mate : float #NOTE: incremented by mating_rate, when it reaches 1, the animal is ready to mate

var age : int
var life_span : int

# energy drain has multiple levels: base_drain, activity_drain, "hyper"_activity_drain, etc.
# animals should have a modifiable value to control when to enter what energy drain state

var max_resources : float

var nutrition: float
var nutrition_norm: float
var seek_nutrition_norm: float = 0.4

var hydration: float
var hydration_norm: float
var seek_hydration_norm: float = 0.4

func get_diet_modifier(food_prefference) -> float:
    # maybe add more modifiers here
    return 1 + food_prefference ** 1.5 # pure carnivores have a 2x modifier, pure herbivores have a 1x modifier

func set_characteristics(genes: Animal_Genes):
    age = 0
    life_span = 500 + round(genes.size * 500.0)

    mass = genes.size

    base_activity_level = genes.speed ** 1.5
    activity_level = base_activity_level # TODO: add energy drains here -> perception, skin_thickness, etc.

    base_metabolic_rate = mass ** 0.75 # Kleiber's Law
    metabolic_rate = float(base_metabolic_rate * activity_level) / normaliser

    diet_modifier = get_diet_modifier(genes.food_prefference)
    food_consumption = metabolic_rate / diet_modifier
    water_consumption = food_consumption * 2

    max_resources = mass/5.0

    nutrition = 0.5 * max_resources
    hydration = 0.5 * max_resources

    ready_to_mate = 0 
