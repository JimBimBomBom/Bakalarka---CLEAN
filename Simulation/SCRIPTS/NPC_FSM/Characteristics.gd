extends CharacterBody2D

class_name Animal_Characteristics

var age: World.Age_Group

# Timers
var change_age_period: float
var sex_cooldown: float

var can_have_sex: bool
var vore_type: World.Vore_Type

# tracking data
var generation: int

#Locomotion
var max_velocity: float
var desired_velocity = Vector2(0, 0)
var direction: Vector2

#Locomotion - Wander variables
var wander_jitter: float
var wander_radius: float
var wander_distance: float
var wander_target: Vector2 # needs to be initialized

var threat_range: float

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
    change_age_period = int(2 + 10 * genes.size + 5 * (1 - genes.metabolic_rate)) * World.change_age_period_mult
    can_have_sex = false
    sex_cooldown = 150 + genes.size * 450

    max_velocity = 1 + 5*genes.musculature # will additionally influenced by for example: fat_storage relative to size, etc.

    var lessen_drain = 200
    energy_drain = (genes.size + genes.musculature + genes.metabolic_rate/3) / lessen_drain
    metabolic_rate = (1 + genes.metabolic_rate) * energy_drain # animal always has to be able to make atleast as much energy as it uses during "normal energy consumption state"
    water_loss = (genes.metabolic_rate + genes.size) / lessen_drain # + insulation + etc. 

    mass = genes.size * 20
    threat_range = genes.sense_range # TODO

    direction = Vector2(randf(), randf()).normalized() # set starting orientation
    wander_jitter = 0.5 * max_velocity
    wander_radius = max_velocity
    wander_distance = max_velocity # NOTE: test value -> always go forward
    wander_target = direction * wander_radius  # start moving in randomly assigned direction

    max_resources = mass - (mass*(genes.musculature/2)) # NOTE: test value
    max_energy = max_resources * 2
    energy = max_energy
    nutrition = 0
    hydration = max_resources

func get_tile_on_curr_pos() -> Vector2:
    var result: Vector2i = position / World.tile_size
    return Vector2(result.x, result.y)

func set_next_move(force: Vector2):
    desired_velocity = force.normalized() * max_velocity

func repulsion_force(creature_position: Vector2): # NOTE: ensures that creatures are kept away from the edges of the world
    if creature_position.x < -World.x_edge_from_center or creature_position.x > World.x_edge_from_center:
        desired_velocity.x = -position.x
    if creature_position.y < -World.y_edge_from_center or creature_position.y > World.y_edge_from_center:
        desired_velocity.y = -position.y

func do_move(delta: float) -> void:
    repulsion_force(position) # keeps animals within the map
    velocity = desired_velocity.normalized() * max_velocity
    if velocity: # used to preserve the direction we were going before we stopped to eat/drink/die
        wander_target = direction * wander_radius
        direction = velocity.normalized()
        rotation = velocity.angle() + PI / 2
        position += velocity * delta # * World.animal_velocity_mult

func seek(target: Vector2) -> Vector2:
    var wanted_velocity = position.direction_to(target) * max_velocity
    return wanted_velocity

func flee(target: Vector2) -> Vector2:
    var my_pos = position
    var wanted_velocity = target.direction_to(position) * max_velocity
    return wanted_velocity

func wander() -> Vector2:
    wander_target += Vector2(randf_range(-wander_jitter, wander_jitter), randf_range(-wander_jitter, wander_jitter))
    wander_target = wander_target.normalized() * wander_radius

    var circle_pos = direction * wander_distance + position
    var target = circle_pos + wander_target
    return seek(target)

func get_flee_dir(animals: Array[Animal]): # -> Vector2:
    var force: Vector2 = Vector2(0, 0)
    for animal in animals:
        var dist: float = abs(position.distance_to(animal.position))
        var temp_force: Vector2 = flee(animal.position)
        force += temp_force / dist
    return force
