extends CharacterBody2D

class_name Animal_Characteristics

var age: World.Age_Group

# Timers
var change_age_period: float
var sex_cooldown: float = 80

var can_have_sex: bool
var vore_type: World.Vore_Type

# tracking data
var generation: int

#Locomotion
var max_velocity: float
var desired_velocity = Vector2(0, 0)
var direction: Vector2

#Locomotion - Wander variables
var wander_jitter: float = 1
var wander_radius: float = 10.0
var wander_distance: float = 30.0
var wander_target: Vector2 # needs to be initialized

var threat_range: float

#Base stats
var energy_drain: float
var metabolic_rate: float

var mass: float
var max_health: float
var health: float
var health_norm: float

var max_resources: float # NOTE: maybe have a max_resource variable for each resource type
var energy: float
var energy_norm: float # NOTE: not used atm

var nutrition: float
var nutrition_norm: float
var seek_nutrition_norm: float = 0.4
var nutrition_satisfied_norm: float = 0.95

var hydration: float
var hydration_norm: float
var seek_hydration_norm: float = 0.4
var hydration_satisfied_norm: float = 0.95

func set_characteristics(genes: Animal_Genes):
    age = World.Age_Group.JUVENILE # TODO option -> have age influence a variety of characteristics ... right now ignored
    change_age_period = int(2 + 2 * genes.size - genes.metabolic_rate) * World.change_age_period_mult
    can_have_sex = false

    #Locomotion
    max_velocity = (genes.agility + genes.musculature) / (genes.size + 1) + 3
    direction = Vector2(randf(), randf()).normalized() # set starting orientation

    wander_jitter = genes.agility + 0.7
    wander_radius = max_velocity
    wander_distance = wander_radius
    wander_target = direction * wander_radius # we want to start by moving forward

    threat_range = genes.sense_range # TODO

    #Base stats
    energy_drain = genes.agility + genes.musculature + genes.size / 2
    metabolic_rate = genes.metabolic_rate

    mass = genes.size * 100
    max_health = mass
    health = max_health

    max_resources = mass / genes.musculature # + World.resource_start_point)
    energy = max_resources
    nutrition = 0
    hydration = 0

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

    var circle_pos = velocity.normalized() * wander_distance + position
    var target = circle_pos + wander_target
    return seek(target)

func get_flee_dir(animals: Array[Animal]): # -> Vector2:
    var force: Vector2 = Vector2(0, 0)
    for animal in animals:
        var dist: float = abs(position.distance_to(animal.position))
        var temp_force: Vector2 = flee(animal.position)
        force += temp_force / dist
    return force
