extends CharacterBody2D

class_name Food_Crop

var yield_value : float
var is_eaten : bool = false

func _ready():
	add_to_group(World.food_crop_group)

func be_eaten():
	if not is_eaten:
		is_eaten = true
		remove_from_group(World.food_crop_group)
		add_to_group(World.food_regrow_group)
		hide()

func regrow():
	var rand = randf_range(0, 1)
	if yield_value > rand:
		is_eaten = false
		remove_from_group(World.food_regrow_group)
		add_to_group(World.food_crop_group)
		show()

