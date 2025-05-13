extends Node

func _ready():
    add_child(World.UI_Statistics)
    add_child(World.Camera)
    
    initialize_simulation()
    run_simulation()

func initialize_simulation():
    World.game_steps = 0
    World.run_simulation = true
    World.simulation_id = Time.get_unix_time_from_system()

    # Create map
    World.Map.generate_world()

    # Create simulation in Rust
    World.create_rust_simulation()

func run_simulation():
    while (World.run_simulation):
        if World.sim_params.max_simulation_step_count != 0 and World.game_steps >= World.sim_params.max_simulation_step_count:
            World.run_simulation = false
            collect_and_log_data() # NOTE: collect data and log it to a file
            _exit_simulation()
            break

        World.simulation.process_turn_for_all_animals() # NOTE: RUST function that handles 1 simulation turn

        if World.game_steps % World.sim_params.data_collection_interval == 0:
            World.Map.update_map_animal_count_labels() # NOTE: update the animal count labels on the map
            collect_and_log_data() # NOTE: collect data and log it to a file
            World.UI_Statistics.update_stats() # NOTE: update UI animal statistics on screen

        World.game_steps += 1

        # Set timer between frames
        if World.sim_params.simulation_speed != 0:
            await get_tree().create_timer(1.0 / World.simulation_speed).timeout

func collect_and_log_data(): # NOTE: this is called by get_data_snapshot_timer
    var world_data = {
        "temperature_avg": World.temperature_avg,
        "moisture_avg": World.moisture_avg,
    }

    var animal_data = World.simulation.get_all_animal_data()

    var log_entry = {
        "timestamp": World.game_steps,
        "world": world_data,
        "animals": animal_data,
    }

    DataLogger.log_data(log_entry)

func run_visualizer():
    var python_executable = "python"  # NOTE: command to run Python3
    var script_path = ProjectSettings.globalize_path("res://../Visualization/visualizer.py")  # Ensure correct path

    # Execute the Python script
    var error = OS.create_process(python_executable, [script_path, str(World.simulation_id)])
    
    if error != OK:
        print("Failed to execute visualizer.py: Error Code", error)

func _exit_simulation():
    DataLogger.save_data_to_file()
    if World.sim_params.generate_graphs:
        run_visualizer() # NOTE: run my Python script on simulation data
    get_tree().quit() # default behavior

func _notification(what):
    if what == NOTIFICATION_WM_CLOSE_REQUEST: # NOTE: this is called when the window is closed
        _exit_simulation()
        # DataLogger.save_data_to_file()
        # if World.generate_graphs:
        #     run_visualizer() # NOTE: run my Python script on simulation data
        # get_tree().quit() # default behavior
