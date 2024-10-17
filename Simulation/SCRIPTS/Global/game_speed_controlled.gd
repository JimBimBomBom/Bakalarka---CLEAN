extends Node

var phys_ticks_per_game_second = 5

func set_game_speed(game_speed):
	Engine.set_time_scale(game_speed)
	Engine.set_physics_ticks_per_second(phys_ticks_per_game_second*game_speed)
	Engine.set_max_physics_steps_per_frame(9999999)
	print("Game speed: ", game_speed)
