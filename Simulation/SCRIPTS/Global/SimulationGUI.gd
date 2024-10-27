extends Control

var game_speed_input
var seed_input
var height_input
var width_input
var carnivores_num_input
var herbivores_num_input

# Called when the node enters the scene tree for the first time.
func _ready():
    game_speed_input = $Panel/GameSpeed/SpinBox
    seed_input = $Panel/MapSeed/SpinBox
    height_input = $Panel/MapHeight/SpinBox
    width_input = $Panel/MapWidth/SpinBox
    carnivores_num_input = $Panel/CarnivoresNum/SpinBox
    herbivores_num_input = $Panel/HerbivoresNum/SpinBox

    var button = $Panel/StartSimulation
    button.pressed.connect(_on_Button_pressed)

func _on_Button_pressed():
    World.game_speed = game_speed_input.value
    World.world_seed = seed_input.value
    World.height = height_input.value
    World.width = width_input.value
    World.carnivore_count = carnivores_num_input.value
    World.herbivore_count = herbivores_num_input.value

    get_tree().change_scene_to_file("res://SCENES/world_scene.tscn")
