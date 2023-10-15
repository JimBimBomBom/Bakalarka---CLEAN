extends CharacterBody2D

class_name Food_Crop

var yield_value : float = 1
var tile_index : Vector2i

# func _ready():
# 	add_to_group(World.food_crop_group)

func be_eaten():
	remove_from_group(World.food_crop_group)
	World.Map.tiles[tile_index].occupied = false
	self.queue_free()
