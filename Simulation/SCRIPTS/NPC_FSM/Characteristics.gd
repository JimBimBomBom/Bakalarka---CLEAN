extends CharacterBody2D

class_name Animal_Characteristics

var age : World.Age_Group
var change_age_period : int

var sexual_partner
var can_have_sex : bool
var vore_type : World.Vore_Type

#Locomotion
var max_velocity : float
var max_steering_force : float
var desired_velocity = Vector2(0, 0)
var direction : Vector2
#Locomotion - Wander variables
var wander_jitter : float = 1
var wander_radius : float = 10.0
var wander_distance : float = 30.0
var wander_target : Vector2 # needs to be initialized

var threat_range : float

var flock_weight : float = 0.4
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
	max_velocity = genes.musculature / genes.size  + 4# hate it
	max_steering_force = genes.agility * 5
	direction = Vector2(randf(), randf()).normalized() # set starting orientation

	wander_jitter = genes.agility * 6
	wander_radius = max_velocity
	wander_distance = wander_radius # 2*max_velocity
	wander_target = direction * wander_radius # we want to moving forward

	threat_range = genes.sense_range # TODO
	flock_behaviour_radius = genes.sense_range/3 # TODO

	#Base stats
	mass = genes.size * 100
	max_health = mass
	health = max_health

	attack_damage = genes.musculature * mass * genes.offense
	attack_range = genes.size * 15

	max_resources = mass / genes.musculature # + World.resource_start_point)
	nutrition = max_resources    /3
	hydration = max_resources    /2

	separation_weight = genes.size 
	cohesion_weight = genes.size 
	alignment_weight = genes.size 

func get_tile_on_curr_pos() -> Vector2:
	var result : Vector2i = position/World.tile_size
	return Vector2(result.x, result.y)

func set_next_move(force : Vector2):
	desired_velocity = force.normalized()*max_velocity

func do_move(delta : float) -> void:
	var my_vel = velocity
	var my_desired_vel = desired_velocity

	var steering_force = (desired_velocity - velocity) * delta
	steering_force.limit_length(max_steering_force)
	velocity += steering_force
	velocity.limit_length(max_velocity)
	if velocity:
		direction = velocity.normalized()
	rotation = velocity.angle() + PI/2
	position += velocity * delta * World.animal_velocity_mult

func do_move_with_flock(delta : float, animals_of_same_type : Array[Animal]):
	var flock_force = flock(animals_of_same_type).limit_length(max_velocity) # ???? 
	var steering_force = (desired_velocity - velocity) + flock_weight*flock_force
	steering_force.limit_length(max_steering_force)

	velocity += steering_force
	velocity.limit_length(max_velocity)
	rotation = velocity.angle() + PI/2
	position += velocity * delta #* World.animal_velocity_mult

func seek(target : Vector2) -> Vector2:
	var wanted_velocity = position.direction_to(target) * max_velocity
	return wanted_velocity

func smooth_seek(target : Vector2) -> Vector2:
	var wanted_velocity = target - position
	return wanted_velocity

func flee(target : Vector2) -> Vector2:
	var my_pos = position
	var wanted_velocity = target.direction_to(position) * max_velocity
	return wanted_velocity

func wander() -> Vector2:
	wander_target = direction * wander_radius
	wander_target += Vector2(randf_range(-wander_jitter, wander_jitter), randf_range(-wander_jitter, wander_jitter))
	wander_target = wander_target.normalized() * wander_radius

	var circle_pos = velocity.normalized() * wander_distance + position
	var target = circle_pos + wander_target
	return smooth_seek(target)

func pursue(target: CharacterBody2D) -> Vector2:
	var to_target = target.position - position
	var relative_heading = velocity.normalized().dot(target.velocity.normalized())
	
	if to_target.dot(velocity.normalized()) > 0 and relative_heading < -0.95:  # cos(18°) is approximately 0.95
		return seek(target.position)
	
	var lookahead_time = to_target.length() / (max_velocity + target.velocity.length())
	var predicted_target = target.position + target.velocity * lookahead_time
	return seek(predicted_target)

func evade(pursuer: CharacterBody2D) -> Vector2:
	var distance = pursuer.position - position
	var estimated_time = distance.length() / max_velocity
	var predicted_position = pursuer.position + pursuer.velocity * estimated_time
	return flee(predicted_position)

func get_flee_dir(animals : Array[Animal]):# -> Vector2:
	var force : Vector2 = Vector2(0, 0)
	for animal in animals:
		var dist : float = abs(position.distance_to(animal.position))
		var temp_force : Vector2 = evade(animal)
		force += temp_force/dist
	return force

func flock(animals_of_same_type : Array[Animal]) -> Vector2:
	var separation_force = separation(animals_of_same_type)
	var alignment_force = alignment(animals_of_same_type)
	var cohesion_force = cohesion(animals_of_same_type)
	
	var flocking_force = separation_force * separation_weight + alignment_force * alignment_weight + cohesion_force * cohesion_weight
	return flocking_force

func separation(animals : Array[Animal]) -> Vector2:
	var force = Vector2()
	for animal in animals:
			var to_animal = position - animal.position
			if to_animal.length() < flock_behaviour_radius:
				force += to_animal.normalized() / to_animal.length()
	return force

func alignment(animals : Array[Animal]) -> Vector2:
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

func cohesion(animals : Array[Animal]) -> Vector2:
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
