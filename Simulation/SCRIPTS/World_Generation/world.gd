extends Node

func _ready():
    add_child(World.UI_Statistics)
    add_child(World.Camera)
    initialize_npcs()
    run_simulation()

func initialize_npcs():
    var spawn_count = 0
    while spawn_count < World.spawn_animal_count:
        # var x_index = min(World.width - 1, max(0, randi_range(World.spawn_animal_location_range_x.x, World.spawn_animal_location_range_x.y)))
        # var y_index = min(World.height - 1, max(0, randi_range(World.spawn_animal_location_range_y.x, World.spawn_animal_location_range_y.y)))
        var x_index = randi_range(0, World.width - 1)
        var y_index = randi_range(0, World.height - 1)

        var index = Vector2i(x_index, y_index)
        if World.Map.tiles[index].biome != World.Biome_Type.Water:
            World.construct_predetermined_npc(index)
            spawn_count += 1

#End of initialization

func age_scent_tracks_on_tile(index):
    var tile = World.Map.tiles[index]
    for scent in tile.scent_trails:
        scent.scent_duration_left -= 1

    # TODO: could probably be made more efficient. is it worthwhile?
    for scent_index in range(tile.scent_trails.size() - 1, -1, -1):
        tile.scent_trails[scent_index].scent_duration_left -= 1
        if tile.scent_trails[scent_index].scent_duration_left <= 0:
            tile.scent_trails.remove_at(scent_index)

func replenish_map():
    for index in World.Map.tiles.keys():
        var tile = World.Map.tiles[index]
        tile.plant_matter += tile.plant_matter_gain
        if tile.plant_matter > tile.max_plant_matter:
            tile.plant_matter = tile.max_plant_matter

        tile.hydration = tile.max_hydration

        if tile.meat_in_rounds.size() > 0:
            for meat in tile.meat_in_rounds:
                meat.spoils_in -= 1
            # Meat can only spoil one meat_in_round at a time
            if tile.meat_in_rounds[-1].spoils_in <= 0:
                tile.total_meat -= tile.meat_in_rounds[-1].amount
                tile.meat_in_rounds.pop_back()
        
        if tile.scent_trails.size() > 0:
            age_scent_tracks_on_tile(index)

func run_simulation():
    while (World.run_simulation):
        for animal in World.animals.values():
            if animal.animal_id not in World.animals:
                continue # NOTE: animal was killed before it could act

            animal.process_animal()
            animal.update_animal_resources()
        
        World.Map.update_map_animal_count_labels() # NOTE: update the animal count labels on the map

        replenish_map()
        if World.game_steps % World.data_collection_interval == 0:
            collect_and_log_data()
            World.UI_Statistics.update_stats(World.animals)

        World.game_steps += 1

        # Set timer between frames
        await get_tree().create_timer(1.0 / World.simulation_speed).timeout

func collect_and_log_data(): # NOTE: this is called by get_data_snapshot_timer
    var world_data = {
        "temperature_avg": World.temperature_avg,
        "moisture_avg": World.moisture_avg,
    }

    var animal_data = []
    for animal in World.animals.values():
        animal_data.append({
            "id": animal.animal_id,
            "vore_type": animal.vore_type,
            "age": animal.age,
            "genes": animal.genes,
        })

    var log_entry = {
        "timestamp": World.game_steps,
        "world": world_data,
        "animals": animal_data,
    }

    DataLogger.log_data(log_entry)

func run_visualizer():
    var python_executable = "python"  # NOTE: command to run Python3
    var script_path = ProjectSettings.globalize_path("res://Processing/visualizer.py")  # Ensure correct path

    # Execute the Python script
    var error = OS.create_process(python_executable, [script_path, str(World.simulation_id)])
    
    if error != OK:
        print("Failed to execute visualizer.py: Error Code", error)

func _notification(what):
    if what == NOTIFICATION_WM_CLOSE_REQUEST: # NOTE: this is called when the window is closed
        DataLogger.save_data_to_file()
        if World.generate_graphs:
            run_visualizer() # NOTE: run my Python script on simulation data
        get_tree().quit() # default behavior
