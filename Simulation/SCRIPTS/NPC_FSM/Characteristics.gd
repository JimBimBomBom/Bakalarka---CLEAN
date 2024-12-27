extends CharacterBody2D

class_name Animal_Characteristics

var age: World.Age_Group

# Timers
var change_age_period: float
# var sex_cooldown: float
# var can_have_sex: bool

# tracking data
var generation: int

#Base stats
var mass: float
var fat_storage: float
var desired_fat_storage: float  # animals will not try to eat more if they were to have more fat storage than this value

# now needs to 
var energy_threshold_to_allow_reproduction: float = World.reproduction_energy_cost * 1.4
var max_energy: float
var energy: float
var energy_norm: float
# how much energy the animal uses per UoT in "normal energy consumption state"
var energy_drain: float
# influences how much food the animal converts additionally to it's energy drain
var metabolic_rate: float
# how much water the animal loses per UoT. depends on metabolic_rate, size, insulation, etc.
var water_loss : float
# how much energy the animal loses per UoT due to weather - heat, cold. Costs energy to have a high insulation value
var insulation : float # NOTE : not used atm

# energy drain has multiple levels: base_drain, activity_drain, "hyper"_activity_drain, etc.
# animals should have a modifiable value to control when to enter what energy drain state

var max_resources: float

var nutrition: float
# var max_nutrition: float
var nutrition_norm: float
var seek_nutrition_norm: float = 0.4
var nutrition_satisfied_norm: float = 0.8

var hydration: float
# var max_hydration: float
var hydration_norm: float
var seek_hydration_norm: float = 0.4
var hydration_satisfied_norm: float = 0.8

func set_characteristics(genes: Animal_Genes):
    age = World.Age_Group.JUVENILE
    # change_age_period = int(2 + 10 * genes.size + 5 * (1 - genes.metabolic_rate)) * World.change_age_period_mult
    # can_have_sex = false
    # sex_cooldown = 150 + genes.size * 450

    # var lessen_drain = 200
    # energy_drain = (genes.size + genes.musculature + genes.metabolic_rate/3) / lessen_drain
    # metabolic_rate = (1 + genes.metabolic_rate) * energy_drain # animal always has to be able to make atleast as much energy as it uses during "normal energy consumption state"
    # water_loss = (genes.metabolic_rate + genes.size) / lessen_drain # + insulation + etc. 

    mass = genes.size * 20

    # max_resources = mass - (mass*(genes.musculature/2)) # NOTE: test value
    max_energy = max_resources * 2
    energy = max_energy
    nutrition = 0
    hydration = max_resources
