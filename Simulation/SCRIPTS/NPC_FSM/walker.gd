class_name walker

#variables
var x
var y


#functions
func display():
	pass
	
func step():
	var choice = randi_range(0, 3)
	
	match choice:
		0:
			x -= 1
		1:
			x += 1
		2:
			y -= 1
		3:
			y += 1
		_:
			print("Oh oh, something wrong with walker script..")
	


