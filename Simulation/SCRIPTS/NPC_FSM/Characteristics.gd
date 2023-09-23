extends CharacterBody2D

class_name Animal_Characteristics

var age : World.Age_Group
var change_age_period : int

var sexual_partner : Animal
var can_have_sex : bool

#Locomotion
var max_velocity : float
var max_steering_force : float
var desired_velocity : Vector2 = (0, 0)
#Locomotion - Wander variables
var wander_jitter : float = 1.0
var wander_radius : float = 20.0
var wander_distance : float = 10.0
var wander_target : Vector2 # needs to be initialized

var threat_range : float

var flock_behaviour_radius : float
var separation_weight : float
var cohesion_weight : float
var alignment_weight : float

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


func set_characteristics(genes : Animal_Genes):
	age = World.Age_Group.JUVENILE # TODO option -> have age influence a variety of characteristics ... right now ignored
	change_age_period = int(genes.size) * int(genes.metabolic_rate) * World.change_age_period_mult * World.hours_in_day
	can_have_sex = true

	#Locomotion
	max_velocity = (genes.musculature + (genes.metabolic_rate/2)) / (genes.size + World.velocity_start_point) # hate it
	max_steering_force = genes.musculature / genes.size

	threat_range = genes.sense_range # TODO
	flock_behaviour_radius = genes.sense_range/3 # TODO

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
	wander_target = Vector2(wander_radius, 0).rotated(randf() * TAU)

func get_tile_on_curr_pos() -> Vector2:
	var result : Vector2i = position/World.tile_size
	return Vector2(result.x, result.y)

func do_move(delta : float) -> void:
	var steering_force = (desired_velocity*max_velocity) - velocity # desired_velocity is always normalized -> *max_vel
	steering_force.limit_length(max_steering_force)
	velocity += steering_force
	velocity.limit_length(max_velocity)
	rotation = velocity.angle() + PI/2
	position += velocity * delta #* World.animal_velocity_mult

func seek(target : Vector2) -> Vector2:
	var desired_velocity = position.direction_to(target) * max_velocity
	return (desired_velocity - velocity).normalized()

func flee(target : Vector2) -> Vector2:
	var desired_velocity = target.direction_to(position) * max_velocity
	return (desired_velocity - velocity).normalized()

func wander() -> Vector2:
	wander_target += Vector2(rand_range(-wander_jitter, wander_jitter), rand_range(-wander_jitter, wander_jitter))
	wander_target = wander_target.normalized() * wander_radius
	var target_world_position = position + (velocity.normalized() * wander_distance) + wander_target
	return seek(target_world_position)

func pursue(target: CharacterBody2D) -> Vector2:
    var to_target = target.position - position
    var relative_heading = velocity.normalized().dot(target.velocity.normalized())
    
    # Check if the target is ahead and facing the character with an angle less than 18 degrees
    if to_target.dot(velocity.normalized()) > 0 and relative_heading < -0.95:  # cos(18°) is approximately 0.95
        return seek(target.position)
    
    # Predict future position
    var lookahead_time = to_target.length() / (max_velocity + target.velocity.length())
    var predicted_target = target.position + target.velocity * lookahead_time
    
    return seek(predicted_target)

func evade(pursuer: CharacterBody2D) -> Vector2:
    var distance = pursuer.position - position
    if distance.length2() > threat_range * threat_range:
        return Vector2()  # No need to evade if pursuer is far away
    
    var estimated_time = distance.length() / max_velocity
    var predicted_position = pursuer.position + pursuer.velocity * estimated_time
    
    return flee(predicted_position)

func get_flee_dir(animals : Array[Animal]) -> Vector2:
	var force : Vector2 = Vector2(0, 0)
	for animal in animals:
		var dist = abs(position.distance_to(animal.position))
		var temp_force = evade(animal)
		force += temp_force/dist
	return force.normalized()

func flock() -> Vector2:
	var separation_force = separation(animals_of_same_type)
	var alignment_force = alignment(animals_of_same_type)
	var cohesion_force = cohesion(animals_of_same_type)
	
	var flocking_force = separation_force * separation_weight + alignment_force * alignment_weight + cohesion_force * cohesion_weight
	return flocking_force

func separation(animals) -> Vector2:
	var force = Vector2()
	for animal in animals:
			var to_animal = position - animal.position
			if to_animal.length() < flock_behaviour_radius:
				force += to_animal.normalized() / to_animal.length()
	return force

func alignment(animals) -> Vector2:
	var avg_velocity = Vector2()
	var count = 0
	for animal in animals:
			var to_animal = position - animal.position
			if to_animal.length() < flock_behaviour_radius:
				avg_velocity += animal.velocity
				count += 1
	if count > 0:
		avg_velocity /= count
		avg_velocity = avg_velocity.normalized() * max_velocity
		return avg_velocity - velocity
	else:
		return Vector2()

func cohesion(animals) -> Vector2:
	var center_mass = Vector2()
	var count = 0
	for animal in animals:
			var to_animal = position - animal.position
			if to_animal.length() < flock_behaviour_radius:
				center_mass += animal.position
				count += 1
	if count > 0:
		center_mass /= count
	return seek(center_mass)

func smooth_seek(target : Vector2) -> Vector2:
	var force = seek(target)
	var dist = position.distance_to(target)
	if dist < 100:
		force *= dist/100
	return force


func pursue(target : Animal) -> Vector2:
	var look_ahead_magnitude = position.distance_to(target.position) / 20
	var force = position.direction_to(target.position + (target.velocity * look_ahead_magnitude))
	return (force - velocity).normalized()

func evade(target : Animal) -> Vector2:
	return pursue(target) * -1


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
