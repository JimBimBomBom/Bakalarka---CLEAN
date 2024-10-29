extends CharacterBody2D

const SPEED = 10.0
func _process(delta):
    var speed = SPEED
    if Input.is_action_pressed("ui_right"):
        position.x += speed
    if Input.is_action_pressed("ui_left"):
        position.x -= speed
    if Input.is_action_pressed("ui_up"):
        position.y -= speed
    if Input.is_action_pressed("ui_down"):
        position.y += speed

    if Input.is_action_just_pressed("speed_up_time"):
        World.game_speed *= 2
        World.game_speed_controller.set_game_speed(World.game_speed)
        
    if Input.is_action_just_pressed("speed_down_time"):
        World.game_speed *= 0.5
        World.game_speed_controller.set_game_speed(World.game_speed)
