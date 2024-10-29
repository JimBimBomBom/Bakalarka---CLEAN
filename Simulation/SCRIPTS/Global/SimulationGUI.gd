extends Control

var game_speed_input
var seed_input
var height_input
var width_input
var food_crop_num_input
var carnivores_num_input
var herbivores_num_input

# Called when the node enters the scene tree for the first time.
func _ready():
    game_speed_input = $Panel/VBoxContainer/GameSpeed/SpinBox
    seed_input = $Panel/VBoxContainer/MapSeed/SpinBox
    height_input = $Panel/VBoxContainer/MapHeight/SpinBox
    width_input = $Panel/VBoxContainer/MapWidth/SpinBox
    food_crop_num_input = $Panel/VBoxContainer/FoodCropNum/SpinBox
    carnivores_num_input = $Panel/VBoxContainer/CarnivoresNum/SpinBox
    herbivores_num_input = $Panel/VBoxContainer/HerbivoresNum/SpinBox

    var button = $Panel/VBoxContainer/StartSimulation
    button.pressed.connect(_on_Button_pressed)

func _on_Button_pressed():
    World.game_speed = game_speed_input.value
    World.world_seed = seed_input.value
    World.height = height_input.value
    World.width = width_input.value
    World.food_crop_count = food_crop_num_input.value
    World.carnivore_count_spawn = carnivores_num_input.value
    World.herbivore_count_spawn = herbivores_num_input.value

    get_tree().change_scene_to_file("res://SCENES/world_scene.tscn")
