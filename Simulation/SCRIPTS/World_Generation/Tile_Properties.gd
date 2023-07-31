class_name Tile_Properties


var tile_type : World.Tile_Type
var tile_index : Vector2i

var curr_food : float
var max_food : float
var food_gain : float

var movement_difficulty : float 

func construct_tile(tile_index_ : Vector2i, tile_type_ : World.Tile_Type,
					curr_food_ : float, max_food_ : float, food_gain_ : float,
					movement_difficulty_ : float):
	tile_index = tile_index_
	tile_type = tile_type_
	curr_food = curr_food_
	max_food = max_food_
	food_gain = food_gain_
	movement_difficulty = movement_difficulty_