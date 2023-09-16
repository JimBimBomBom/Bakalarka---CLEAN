extends CharacterBody2D

class_name Animal_Characteristics

var age : World.Age_Group
var change_age_period : int

var sexual_partner : Animal
var can_have_sex : bool

#Locomotion
var max_velocity : float
var acceleration : Vector2
var max_steering_force : float

#Base stats
var mass : float
var max_health : float
var health : float
var health_norm : float

var attack_damage : float
var attack_range : float

var max_resources : float
var hunger : float
var hydration : float
var hunger_norm : float
var hydration_norm : float

var separation_radius : float
var cohesion_radius : float
var alignment_radius : float

# var x_dir_noise = FastNoiseLite.new()
# var x_offset = 0.0

# var y_dir_noise = FastNoiseLite.new()
# var y_offset = 0.0

# var theta : float = 0
# var wander_radius : float = 40
# var wander_offset : float = 100

# func _init():
# 	x_dir_noise.seed = randi()
# 	y_dir_noise.seed = randi()

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
	hunger = max_resources
	hydration = max_resources

	separation_radius = genes.size * 15
	cohesion_radius = 100
	alignment_radius = 100

func get_tile_on_curr_pos() -> Vector2:
	var result : Vector2i = position/World.tile_size
	return Vector2(result.x, result.y)

func move_calc(force : Vector2) -> void:
	acceleration += force

func do_move(delta : float) -> void:
	# var terrain_difficulty = World.Map.tiles[get_tile_on_curr_pos()].movement_difficulty
	velocity += acceleration.normalized() * max_steering_force * delta * World.animal_acceleration_mult#* terrain_difficulty
	rotation = velocity.angle() + PI/2
	if velocity.length() > max_velocity:
		velocity = velocity.normalized()*max_velocity
	position += velocity * delta * World.animal_velocity_mult

# func wander() -> Vector2:
# 	theta += randf_range(-0.25, 0.25)
# 	var x = cos(theta) * wander_radius + (curr_pos.x + curr_velocity.normalized().x * wander_offset)
# 	var y = sin(theta) * wander_radius + (curr_pos.y + curr_velocity.normalized().y * wander_offset)

# 	var force = curr_pos.direction_to(Vector2(x, y))
# 	return force

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
