extends StaticBody2D

class_name Food_Crop

var yield_value : float = World.food_crop_yield
var tile_index : Vector2i

func be_eaten():
    World.Map.tiles[tile_index].occupied = false
    queue_free()
