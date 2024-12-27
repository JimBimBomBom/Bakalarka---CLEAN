extends Control

# Example stats
var animals : Array[Animal] = []
var animal_count = 0
var avg_size = 0
var size_range = Vector2i(0, 0)

@onready var animal_count_label : Label = $PanelContainer/MarginContainer/VBox_Statistics/AnimalCount


func _ready():
    update_stats()
# Control/PanelContainer/MarginContainer/VBox_Statistics/SizeRange
func update_stats():
    animal_count_label.text = "Animal Count: %d" % animal_count
    # $VBox_Statistics/Label2.Text = "Average Size: %d" % avg_size
    # $VBox_Statistics/Label3.Text = "Size Range: %d to %d" % [size_range.x, size_range.y]

func set_stats(animals):
    self.animals = animals
    animal_count = get_animal_count()
    avg_size = get_avg_size()
    size_range = get_size_range()
    update_stats()

func get_animal_count():
    return animals.size()

func get_avg_size():
    var total_size = 0
    for animal in animals:
        total_size += animal.size
    return total_size / animals.size()

func get_size_range():
    var min_size : float = 1
    var max_size : float = 0
    for animal in animals:
        if animal.size < min_size:
            min_size = animal.size
        if animal.size > max_size:
            max_size = animal.size
    return Vector2(min_size, max_size)
