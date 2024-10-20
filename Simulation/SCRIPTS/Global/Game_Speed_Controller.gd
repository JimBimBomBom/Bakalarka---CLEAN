extends RefCounted

class_name GameSpeedController

func set_game_speed(game_speed):
    Engine.set_time_scale(game_speed)
    Engine.set_physics_ticks_per_second(World.phys_ticks_per_game_second*game_speed)
    Engine.set_max_physics_steps_per_frame(9999999)
    World.game_speed = game_speed
    print("Game speed: ", game_speed)
