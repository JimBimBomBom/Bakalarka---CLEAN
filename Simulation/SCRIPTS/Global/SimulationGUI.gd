extends CanvasLayer

var game_speed_input
var seed_input
var height_input
var width_input
var animal_spawn_count
var generate_graphs_input

var sim_param_file_input

# Called when the node enters the scene tree for the first time.
func _ready():
    add_child(World.Camera)
    game_speed_input = $Control/PanelContainer/Panel/VBoxContainer/GameSpeed/SpinBox
    seed_input = $Control/PanelContainer/Panel/VBoxContainer/MapSeed/SpinBox
    height_input = $Control/PanelContainer/Panel/VBoxContainer/MapHeight/SpinBox
    width_input = $Control/PanelContainer/Panel/VBoxContainer/MapWidth/SpinBox
    animal_spawn_count = $Control/PanelContainer/Panel/VBoxContainer/AnimalSpawnCount/SpinBox
    generate_graphs_input = $Control/PanelContainer/Panel/VBoxContainer/GenerateGraphs/SpinBox

    sim_param_file_input = $Control/PanelContainer/Panel/VBoxContainer/SimulationParametersFile/LineEdit

    var Start_Simulation_Button = $Control/PanelContainer/Panel/VBoxContainer/StartSimulation
    Start_Simulation_Button.pressed.connect(_on_Start_Simulation_Button_pressed)

    var Generate_World_Button = $Control/PanelContainer/Panel/VBoxContainer/GenerateWorld
    Generate_World_Button.pressed.connect(_on_Generate_World_Button_pressed)

    if sim_param_file_input.text == "":
        World.simulation_parameters_file = "res://PARAMS/test"
    else:
        World.simulation_parameters_file = "res://PARAMS/" + sim_param_file_input.text
    
    # Load simulation parameters from file and use them as default values
    World.sim_params.load_from_file(World.simulation_parameters_file)

    width_input.value = World.sim_params.width
    height_input.value = World.sim_params.height

func _on_Generate_World_Button_pressed():
    if seed_input.value == 0:
        World.world_seed = randi_range(1, 10000)
    else:
        World.world_seed = seed_input.value

    if height_input.value != 0:
        World.sim_params.height = height_input.value
    if width_input.value != 0:
        World.sim_params.width = width_input.value

    World.Map.generate_world()
    World.world_initialized = true

    World.generate_graphs = generate_graphs_input.value

func _on_Start_Simulation_Button_pressed():
    if World.world_initialized == false:
        return

    World.simulation_speed = game_speed_input.value
    World.spawn_animal_count = animal_spawn_count.value
    remove_child(World.Camera)

    get_tree().change_scene_to_file("res://SCENES/world_scene.tscn")
