extends CanvasLayer

@onready var world_age_label : Label = $Control/PanelContainer/MarginContainer/VBox_Statistics/WorldAge
@onready var animal_count_label : Label = $Control/PanelContainer/MarginContainer/VBox_Statistics/AnimalCount

@onready var animal_size_avg_label : Label = $Control/PanelContainer/MarginContainer/VBox_Statistics/SizeAverage
@onready var animal_size_range_label : Label = $Control/PanelContainer/MarginContainer/VBox_Statistics/SizeRange

@onready var animal_speed_avg_label : Label = $Control/PanelContainer/MarginContainer/VBox_Statistics/SpeedAverage
@onready var animal_speed_range_label : Label = $Control/PanelContainer/MarginContainer/VBox_Statistics/SpeedRange

@onready var animal_mate_rate_avg_label : Label = $Control/PanelContainer/MarginContainer/VBox_Statistics/MatingRateAverage
@onready var animal_mate_rate_range_label : Label = $Control/PanelContainer/MarginContainer/VBox_Statistics/MatingRateRange

@onready var animal_food_prefference_avg_label : Label = $Control/PanelContainer/MarginContainer/VBox_Statistics/FoodPrefferenceAverage
@onready var animal_food_prefference_range_label : Label = $Control/PanelContainer/MarginContainer/VBox_Statistics/FoodPrefferenceRange

@onready var animal_nutrition_avg_label : Label = $Control/PanelContainer/MarginContainer/VBox_Statistics/NutritionAverage
@onready var animal_hydration_avg_label : Label = $Control/PanelContainer/MarginContainer/VBox_Statistics/HydrationAverage
@onready var animal_love_avg_label : Label = $Control/PanelContainer/MarginContainer/VBox_Statistics/LoveAverage

@onready var animal_died_starvation: Label = $Control/PanelContainer/MarginContainer/VBox_Statistics/DeathsStarvation
@onready var animal_died_dehydration: Label = $Control/PanelContainer/MarginContainer/VBox_Statistics/DeathsDehydration
@onready var animal_died_age: Label = $Control/PanelContainer/MarginContainer/VBox_Statistics/DeathsAge
@onready var animal_died_predation: Label = $Control/PanelContainer/MarginContainer/VBox_Statistics/DeathsPredation

@onready var nutrition_from_meat: Label = $Control/PanelContainer/MarginContainer/VBox_Statistics/NutritionFromMeat
@onready var nutrition_from_plants: Label = $Control/PanelContainer/MarginContainer/VBox_Statistics/NutritionFromPlants

func update_stats(animals):
    world_age_label.text = "World Age: %d" % World.game_steps
    if animals.size() == 0:
        # set_animal_statistics_to_zero()
        return

    animal_count_label.text = "Animal Count: %d" % get_animal_count(World.animals)

    animal_size_avg_label.text = "Average Size: %.2f" % get_avg_size(World.animals)
    var size_range = get_size_range(World.animals)
    animal_size_range_label.text = "Size Range: %.2f - %.2f" % [size_range.x, size_range.y]

    animal_speed_avg_label.text = "Speed Average: %.2f" % get_avg_speed(World.animals)
    var speed_range = get_speed_range(World.animals)
    animal_speed_range_label.text = "Speed Range: %.2f - %.2f" % [speed_range.x, speed_range.y]

    animal_mate_rate_avg_label.text = "MatingRate Average: %.2f" % get_avg_mating_rate(World.animals)
    var mate_rate_range = get_mating_rate_range(World.animals)
    animal_mate_rate_range_label.text = "MatingRate Range: %.2f - %.2f" % [mate_rate_range.x, mate_rate_range.y]

    animal_food_prefference_avg_label.text = "FoodPreff Average: %.2f" % get_avg_food_prefference(World.animals)
    var food_prefference_range = get_food_prefference_range(World.animals)
    animal_food_prefference_range_label.text = "FoodPreff Range: %.2f - %.2f" % [food_prefference_range.x, food_prefference_range.y]

    animal_nutrition_avg_label.text = "Nutrition Average: %.2f" % get_nutrition_avg(World.animals)
    animal_hydration_avg_label.text = "Hydration Average: %.2f" % get_hydration_avg(World.animals)
    animal_love_avg_label.text = "Love Average: %.2f" % get_love_avg(World.animals)

    animal_died_starvation.text = "Deaths Starvation: %d" % World.animal_deaths_starvation
    animal_died_dehydration.text = "Deaths Dehydration: %d" % World.animal_deaths_dehydration
    animal_died_age.text = "Deaths Age: %d" % World.animal_deaths_age
    animal_died_predation.text = "Deaths Predation: %d" % World.animal_deaths_predation

    nutrition_from_meat.text = "Nutrition Meat: %.2f" % World.nutrition_from_meat
    nutrition_from_plants.text = "Nutrition Plants: %.2f" % World.nutrition_from_plants

func set_animal_statistics_to_zero():
    animal_count_label.text = "Animal Count: 0"
    animal_size_avg_label.text = "Average Size: 0"
    animal_size_range_label.text = "Size Range: 0 - 0"
    animal_nutrition_avg_label.text = "Nutrition Average: 0"
    animal_hydration_avg_label.text = "Hydration Average: 0"
    animal_love_avg_label.text = "Love Average: 0"

func get_animal_count(animals):
    return animals.size()

func get_avg_speed(animals):
    var total_speed = 0
    for animal in animals.values():
        total_speed += animal.genes.speed
    return total_speed / animals.size()

func get_speed_range(animals):
    var min_speed : float = 1
    var max_speed : float = 0
    for animal in animals.values():
        var speed = animal.genes.speed
        if speed < min_speed:
            min_speed = speed
        if speed > max_speed:
            max_speed = speed
    return Vector2(min_speed, max_speed)

func get_avg_mating_rate(animals):
    var total_mating_rate = 0
    for animal in animals.values():
        total_mating_rate += animal.genes.mating_rate
    return total_mating_rate / animals.size()

func get_mating_rate_range(animals):
    var min_mating_rate : float = 1
    var max_mating_rate : float = 0
    for animal in animals.values():
        var mating_rate = animal.genes.mating_rate
        if mating_rate < min_mating_rate:
            min_mating_rate = mating_rate
        if mating_rate > max_mating_rate:
            max_mating_rate = mating_rate
    return Vector2(min_mating_rate, max_mating_rate)

func get_avg_food_prefference(animals):
    var total_food_prefference = 0
    for animal in animals.values():
        total_food_prefference += animal.genes.food_prefference
    return total_food_prefference / animals.size()

func get_food_prefference_range(animals):
    var min_food_prefference : float = 1
    var max_food_prefference : float = 0
    for animal in animals.values():
        var food_prefference = animal.genes.food_prefference
        if food_prefference < min_food_prefference:
            min_food_prefference = food_prefference
        if food_prefference > max_food_prefference:
            max_food_prefference = food_prefference
    return Vector2(min_food_prefference, max_food_prefference)

func get_avg_size(animals):
    var total_size = 0
    for animal in animals.values():
        var size = animal.genes.size
        total_size += size
    return total_size / animals.size()

func get_size_range(animals):
    var min_size : float = 1
    var max_size : float = 0
    for animal in animals.values():
        var size = animal.genes.size
        if size < min_size:
            min_size = size
        if size > max_size:
            max_size = size
    return Vector2(min_size, max_size)

func get_nutrition_avg(animals):
    var total_nutrition = 0
    for animal in animals.values():
        total_nutrition += animal.nutrition_norm
    return total_nutrition / animals.size()

func get_hydration_avg(animals):
    var total_hydration = 0
    for animal in animals.values():
        total_hydration += animal.hydration_norm
    return total_hydration / animals.size()

func get_love_avg(animals):
    var total_love = 0
    for animal in animals.values():
        total_love += animal.ready_to_mate
    return total_love / animals.size()
