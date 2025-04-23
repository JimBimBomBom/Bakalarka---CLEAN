extends Camera2D

@export var camera_speed: float = 500.0  # Speed of camera movement

func _process(delta: float):
    var input = Vector2.ZERO
    if Input.is_action_pressed("ui_up"):
        input.y -= 1
    if Input.is_action_pressed("ui_down"):
        input.y += 1
    if Input.is_action_pressed("ui_left"):
        input.x -= 1
    if Input.is_action_pressed("ui_right"):
        input.x += 1

    # Move the camera
    position += input.normalized() * camera_speed * delta
