extends Node

# right now we only save_data_to_file only data about animals

var data = []

func log_data(entry):
    data.append(entry)
    if data.size() > 1000:
        save_data_to_file()
        data.clear()

func save_data_to_file():
    #Store as CSV
    var file_name = "user://simulation_data-" + str(World.simulation_id) + ".csv"
    var file = FileAccess.open(file_name, FileAccess.WRITE)
    var header = "timestamp,animal_id,vore_type,age,size,speed,food_prefference,mating_rate\n"
    file.store_string(header)

    for entry in data:
        var timestamp = entry["timestamp"]
        for animal in entry['animals']:
            var line = "%d,%d,%d,%d,%f,%f,%f,%f\n" % [
                timestamp,
                animal['id'],
                animal['vore_type'],
                animal['age'],
                animal['genes']['size'],
                animal['genes']['speed'],
                animal['genes']['food_prefference'],
                animal['genes']['mating_rate'],
            ]
            file.store_string(line)
    file.close()
