extends Npc_Class
class_name Npc_Properties_Class

enum Vore_Type {
	CARNIVORE,
	HERBIVORE,
	OMNIVORE,
}

var vore_type : Vore_Type
#var senses : Senses_Class
var behaviour : Behaviour_Class 
var curr_energy_level
var max_energy_level
var mass
var curr_hunger
var max_hunger
var curr_hydration
var max_hydration
var speed

#Sight
var sight_acuity
var sight_range
var field_of_view

var night_vision_acuity
var day_vision_acuity

func construct(type):
	vore_type = type

# func _process():
# 	var angle = 90 - rad2deg(facing_in_direction.angle())

# 	for node in get_tree().get_nodes_in_group('detectable'):
# 		if pos.distance_to(node.pos) < sight_range:
# 			var dot_product = facing_in_direction.dot(node.direction)
# 			var angle_to_node = rad2deg(acos(dot_product))
# 			if angle_to_node < field_of_view/2
# 				pass # TODO implement logic




