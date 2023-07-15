extends CharacterBody2D
class_name Npc_Class

# @onready var world = get_node("World_Generation")

var curr_pos : Vector2 = Vector2(0, 0)
var facing_in_direction : Vector2 # TODO keep this vec normalized at all times
var curr_velocity : Vector2
var max_velocity : float = 0.3
var acceleration : Vector2 = Vector2(0, 0)
var max_acceleration : float = 1.0

var max_steering_force : float 


var properties : Npc_Properties_Class
var sense_range : int

var x_dir_noise = FastNoiseLite.new()
var x_offset = 0.0

var y_dir_noise = FastNoiseLite.new()
var y_offset = 0.0

func constructor(pos, sense_range_, maximum_velocity, maximum_steering_force, type):
	curr_pos = pos*Vector2(16, 16)
	position = curr_pos
	sense_range = sense_range_
	max_velocity = maximum_velocity
	max_steering_force = maximum_steering_force
	curr_velocity = Vector2(0, 0)
	acceleration = Vector2(0, 0)

	properties = Npc_Properties_Class.new()
	#properties.vore_type = type
	properties.construct(type)
	# properties = Npc_Properties_Class.constructor(type, mass_)

	x_dir_noise.seed = randi()
	y_dir_noise.seed = randi()
	
func get_force_dir_from_senses(target) -> Vector2:
	var desired = (target - curr_pos)
	return desired.normalized()

func seek(target: Vector2):
	var force_dir = get_force_dir_from_senses(target)
	var steering_force = force_dir * max_steering_force
	apply_force(steering_force)

func flee(target: Vector2):
	var force_dir = get_force_dir_from_senses(target)
	var steering_force = force_dir * max_steering_force
	apply_force(steering_force * -1)

func apply_force(force):
	acceleration += force

func move():
	#TODO add energy consumption
	acceleration = acceleration.normalized()*max_acceleration
	curr_velocity += acceleration
	if curr_velocity.length() > max_velocity:
		curr_velocity = curr_velocity.normalized()*max_velocity
	curr_pos += curr_velocity
	acceleration *= 0

func within_range(range: float, pos1: Vector2, pos2: Vector2) -> bool:
	if abs((pos1 - pos2).length()) < range:
		return true
	return false

func get_objects_in_range(sens_range: float) -> Array[CharacterBody2D]:
	var result : Array[CharacterBody2D]
	var parentNode = owner.get_node(".")
	for i in range(parentNode.get_child_count()):
		var childNode = parentNode.get_child(i)
		# if childNode.objectType == "CharacterBody2D":
		if childNode.is_class("CharacterBody2D"):
			if within_range(sens_range, childNode.position, curr_pos):
				result.append(childNode)
	return result

func is_object_in_range(range) -> bool:
	if get_objects_in_range(range).size() > 0:
		return true
	return false
	
func rand_walk(magnitude):
	var move_change = 0.1
	var dir = Vector2(x_dir_noise.get_noise_1d(x_offset), y_dir_noise.get_noise_1d(y_offset))
	x_offset += move_change
	y_offset += move_change
	apply_force(dir.normalized()*magnitude)

func new_react(range):
	var npcs = get_tree().get_nodes_in_group("NPCs")
	for npc in npcs:
		if not is_npc_in_range(range, curr_pos, npc.curr_pos):
			continue

		if properties.vore_type == World.Vore_Type.CARNIVORE and npc.properties.vore_type == World.Vore_Type.HERBIVORE:
			seek(npc.position)
		elif properties.vore_type == World.Vore_Type.HERBIVORE and npc.properties.vore_type == World.Vore_Type.CARNIVORE:
			flee(npc.position)

func is_npc_in_range(range, npc1_pos, npc2_pos):
	if abs((npc1_pos - npc2_pos).length()) < range:
		return true
	return false


func _physics_process(delta):
	new_react(sense_range)
	#rand_walk(0.002)
	move()
	position = curr_pos

