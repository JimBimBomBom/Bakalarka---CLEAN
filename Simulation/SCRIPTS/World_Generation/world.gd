extends Node

func _ready():
    add_child(World.Camera)
    add_child(World.Map)
    World.Map.generate_world()
    add_child(World.UI_Statistics)

    initialize_npcs()

func initialize_npcs():
    var spawn_count = 0
    while spawn_count < World.spawn_animal_count:
        var index = Vector2i(randi_range(0, World.width), randi_range(0, World.height))
        if World.Map.tiles[index].biome != World.Biome_Type.Water:
            construct_npc(index)
            spawn_count += 1

func construct_npc(index):
    var animal = World.Animal.new()
    animal.construct_animal()
    World.Map.tiles[index].animals.append(animal)

#End of initialization

func _on_animal_birth_request(pos, parent_1, parent_2):
    var animal = World.Animal.new()
    animal.spawn_animal(parent_1, parent_2)
    World.Map.tiles[pos].animals.append(animal)

func between(val, start, end):
    if start <= val and val <= end:
        return true
    return false

func _collect_and_log_data(): # NOTE: this is called by get_data_snapshot_timer
    var animal_data = []
    for tile in World.Map.tiles:
        for animal in tile.animals:
            animal_data.append({
                "id": animal.get_instance_id(),
                "animal_type": animal.animal_type,
                "age": animal.age,
                "genes": animal.genes,
            })
    var world_data = {
        "temperature_avg": World.temperature_avg,
        "moisture_avg": World.moisture_avg,
    }
    var log_entry = {
        "timestamp": World.game_time,
        "animals": animal_data,
        "world": world_data,
    }
    DataLogger.log_data(log_entry)

func _notification(what):
    if what == NOTIFICATION_WM_CLOSE_REQUEST:
        DataLogger.save_data_to_file()
        get_tree().quit() # default behavior
