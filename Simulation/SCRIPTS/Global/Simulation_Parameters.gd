class_name Simulation_Parameters
# extends Node

var width : int = 0
var height : int = 0

var max_genetic_distance : float = 0.0
var min_allowed_genetic_distance : float = 0.0

var mutation_prob : float = 0.0
var mutation_half_range : float = 0.0

var scent_duration : int = 0

var normaliser: float = 0.0

# TODO: add more customizable variables

func load_from_file(path : String) -> void:
    var file = FileAccess.open(path, FileAccess.READ)
    if file:
        while not file.eof_reached():
            var line = file.get_line().strip_edges()
            if line == "" or line.begins_with("#"):
                continue # skip empty lines and comments
            var parts = line.split(",")
            if parts.size() == 2:
                var key = parts[0].strip_edges()
                var value = parts[1].strip_edges()
                _apply_key_value(key, value)
    else:
        push_error("Failed to open parameters file at: " + path)

# Get key-value pairs specified in file safely
func _apply_key_value(key: String, value: String) -> void:
    for property in World.sim_params.get_property_list():
        if key in property.name:
            var current_value = get(key)
            if typeof(current_value) == TYPE_INT:
                set(key, int(value))
            elif typeof(current_value) == TYPE_FLOAT:
                set(key, float(value))
            elif typeof(current_value) == TYPE_STRING:
                set(key, value)
            else:
                push_warning("Unsupported type for key: " + key)
        else:
            push_warning("Unknown parameter: " + key)

func _ready():
    # Default values
    width = 100
    height = 100
    # NOTE: each genes plays a role in the genetic distance calculation (food_preference is emphasized)
    max_genetic_distance = 1 + 1 + 3*1 + 1 + 1 + 1
    min_allowed_genetic_distance = 0.8
    mutation_prob = 0.05
    mutation_half_range = 0.05
    scent_duration = 20
    normaliser = 200.0 # TODO: set this to a proper value based on the simulation requirements
