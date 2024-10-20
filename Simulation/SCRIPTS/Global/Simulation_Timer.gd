extends RefCounted

class_name SimulationTimer

var time: float
var trigger_time: float
var active: bool
signal timer_triggered

func do_timer(delta: float, deactivate: bool = false) -> void:
	if active:
		time += delta
		if time >= trigger_time:
			emit_signal("timer_triggered")
			time = 0
			if deactivate:
				active = false
