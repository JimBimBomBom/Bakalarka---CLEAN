extends CharacterBody2D

class_name Npc_Class

var curr_pos : Vector2 = Vector2(0, 0)
var curr_velocity : Vector2 = Vector2(0, 0)
var max_velocity : float = 0.3
var acceleration : Vector2 = Vector2(0, 0)
var max_steering_force : float 

var x_dir_noise = FastNoiseLite.new()
var x_offset = 0.0

var y_dir_noise = FastNoiseLite.new()
var y_offset = 0.0

var theta : float = 0
var wander_radius : float = 40
var wander_offset : float = 100

func _init():
	x_dir_noise.seed = randi()
	y_dir_noise.seed = randi()

func construct_npc(curr_pos_ : Vector2, max_velocity_ : float, max_steering_force_ : float,
					wander_radius_ : float, wander_offset_ : float) :
	curr_pos = curr_pos_
	max_velocity = max_velocity_
	max_steering_force = max_steering_force_
	wander_radius = wander_radius_
	wander_offset = wander_offset_

func move_new(force):
	curr_velocity += force * max_steering_force
	# curr_velocity.limit_length(max_velocity)
	rotation = curr_velocity.angle() + PI/2
	if curr_velocity.length() > max_velocity:
		curr_velocity = curr_velocity.normalized()*max_velocity
	curr_pos += curr_velocity

func wander() -> Vector2:
	theta += randf_range(-0.05, 0.05)
	var x = cos(theta) * wander_radius + (curr_pos.x + curr_velocity.normalized().x * wander_offset)
	var y = sin(theta) * wander_radius + (curr_pos.y + curr_velocity.normalized().y * wander_offset)

	var force = curr_pos.direction_to(Vector2(x, y))
	return force

func seek(target : Vector2) -> Vector2:
	var force = curr_pos.direction_to(target) * max_velocity
	return (force - curr_velocity).normalized()

func flee(target : Vector2) -> Vector2:
	return seek(target) * -1

func pursue(target : Animal) -> Vector2:
	var magnitude = curr_pos.distance_to(target.curr_pos) / 20
	var force = curr_pos.direction_to(target.curr_pos + (target.curr_velocity * magnitude))
	return (force - curr_velocity).normalized()

func evade(target : Animal) -> Vector2:
	return pursue(target) * -1
