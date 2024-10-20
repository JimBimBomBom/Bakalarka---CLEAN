extends StaticBody2D

class_name Cadaver

var corpse_timer: SimulationTimer
var nutrition : float
# var nutrition : float #NOTE: should nutrition be considered here?

func _free_cadaver():
	queue_free()

func _physics_process(delta):
	corpse_timer.do_timer(delta)

func _ready():
	corpse_timer = SimulationTimer.new()
	corpse_timer.trigger_time = World.corpse_time
	corpse_timer.active = true
	corpse_timer.timer_triggered.connect(_free_cadaver)
