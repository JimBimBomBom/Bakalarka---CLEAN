extends Node
# right now we only save_data_to_file only data about animals

var data = []

func log_data(entry):
    data.append(entry)
    if data.size() > 1:
        save_data_to_file()
        data.clear()

func create_new_file_add_header(file_name):
    var file = FileAccess.open(file_name, FileAccess.WRITE) # NOTE: WRITE mode creates a new file or truncates an existing file
    var header = "timestamp,animal_id,vore_type,age,size,speed,food_prefference,mating_rate"
    file.store_line(header)
    file.close()

func save_data_to_file():
    var file_name = "user://simulation_data-" + str(World.simulation_id) + ".csv"
    var file_exists = FileAccess.file_exists(file_name)

    if not file_exists:
        create_new_file_add_header(file_name)

    # Append data to file
    var file = FileAccess.open(file_name, FileAccess.READ_WRITE) # NOTE: READ_WRITE mode is the only one that does not truncate an existing file and allows us to append to it
    file.seek_end()
    for entry in data:
        var timestamp = entry["timestamp"]
        for animal in entry['animals']:
            var line = "%d,%d,%d,%d,%f,%f,%f,%f" % [
                timestamp,
                animal['id'],
                animal['vore_type'],
                animal['age'],
                animal['genes']['size'],
                animal['genes']['speed'],
                animal['genes']['food_prefference'],
                animal['genes']['mating_rate'],
            ]
            file.store_line(line)
    file.close()
