extends CharacterBody2D

class_name Animal_Characteristics

var age : World.Age_Group
var change_age_period : int

var sexual_partner : Animal
var can_have_sex : bool

#Locomotion
var max_velocity : float
var desired_velocity : Vector2
var max_steering_force : float
#Locomotion addons
var time_step : float
var time_value : float
const MAX_ANGLE_CHANGE : float = 0.1
var wander_noise = FastNoiseLite.new()


#Base stats
var mass : float
var max_health : float
var health : float
var health_norm : float

var attack_damage : float
var attack_range : float

var max_resources : float
var nutrition : float
var nutrition_norm : float
var seek_nutrition_norm : float = 0.8
var hydration : float
var hydration_norm : float
var seek_hydration_norm : float = 0.3

var separation_radius : float
var cohesion_radius : float
var alignment_radius : float

func set_characteristics(genes : Animal_Genes):
	age = World.Age_Group.JUVENILE # TODO option -> have age influence a variety of characteristics ... right now ignored
	change_age_period = int(genes.size) * int(genes.metabolic_rate) * World.change_age_period_mult * World.hours_in_day
	can_have_sex = true

	#Locomotion
	max_velocity = (genes.musculature + (genes.metabolic_rate/2)) / (genes.size + World.velocity_start_point) # hate it
	velocity = Vector2(0, 0)
	acceleration = Vector2(0, 0)
	max_steering_force = genes.musculature / genes.size

	#Base stats
	mass = genes.size * 100
	max_health = mass
	health = max_health

	attack_damage = genes.musculature * mass * genes.offense
	attack_range = genes.size * 15

	max_resources = mass / (genes.musculature + World.resource_start_point)
	nutrition = max_resources    /3
	hydration = max_resources    /2

	separation_radius = genes.size * 15
	cohesion_radius = 100
	alignment_radius = 100

func _ready():
	# wander_noise.seed = randi()
	wander_noise.seed = 1581123

func get_tile_on_curr_pos() -> Vector2:
	var result : Vector2i = position/World.tile_size
	return Vector2(result.x, result.y)


func do_move(delta : float) -> void:
	var steering_force = desired_velocity - velocity 
	steering_force.limit_length(max_steering_force)
	velocity += steering_force
	velocity.limit_length(max_velocity)
	rotation = velocity.angle() + PI/2
	position += velocity * delta #* World.animal_velocity_mult

func wander(delta: float) -> Vector2:
	# Increment wander_angle using noise
	wander_angle += (noise.get_noise_2d(wander_angle, 0) - 0.5) * angle_change

	var circle_x = position.x + wander_radius * cos(wander_angle)
	var circle_y = position.y + wander_radius * sin(wander_angle)

	# Get the desired direction towards the point on the circle
	return Vector2(circle_x - position.x, circle_y - position.y).normalized()







func move_calc(force : Vector2) -> void:
	acceleration += force

func seek(target : Vector2) -> Vector2:
	var force = position.direction_to(target) * max_velocity
	return (force - velocity).normalized()

func smooth_seek(target : Vector2) -> Vector2:
	var force = seek(target)
	var dist = position.distance_to(target)
	if dist < 100:
		force *= dist/100
	return force

func flee(target : Vector2) -> Vector2:
	return seek(target) * -1

func pursue(target : Animal) -> Vector2:
	var look_ahead_magnitude = position.distance_to(target.position) / 20
	var force = position.direction_to(target.position + (target.velocity * look_ahead_magnitude))
	return (force - velocity).normalized()

func evade(target : Animal) -> Vector2:
	return pursue(target) * -1

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
	return target.velocity.normalized()

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
	var force : Vector2 = wander()
	var force = Vector2(0, 0)
	if not animals.is_empty():
		force += get_flock_dir(animals)
	return force