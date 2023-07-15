extends CharacterBody2D

const SPEED = 10.0
func _physics_process(delta):
	if Input.is_action_pressed("ui_right"):
		position.x += SPEED
	if Input.is_action_pressed("ui_left"):
		position.x -= SPEED
	if Input.is_action_pressed("ui_up"):
		position.y -= SPEED
	if Input.is_action_pressed("ui_down"):
		position.y += SPEED
