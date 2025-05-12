extends CanvasLayer

@onready var world_age_label : Label = $Control/PanelContainer/MarginContainer/VBox_Statistics/WorldAge
@onready var animal_count_label : Label = $Control/PanelContainer/MarginContainer/VBox_Statistics/AnimalCount

@onready var animal_size_avg_label : Label = $Control/PanelContainer/MarginContainer/VBox_Statistics/SizeAverage
@onready var animal_size_range_label : Label = $Control/PanelContainer/MarginContainer/VBox_Statistics/SizeRange

@onready var animal_speed_avg_label : Label = $Control/PanelContainer/MarginContainer/VBox_Statistics/SpeedAverage
@onready var animal_speed_range_label : Label = $Control/PanelContainer/MarginContainer/VBox_Statistics/SpeedRange

@onready var animal_mate_rate_avg_label : Label = $Control/PanelContainer/MarginContainer/VBox_Statistics/MatingRateAverage
@onready var animal_mate_rate_range_label : Label = $Control/PanelContainer/MarginContainer/VBox_Statistics/MatingRateRange

@onready var animal_food_preference_avg_label : Label = $Control/PanelContainer/MarginContainer/VBox_Statistics/FoodPreferenceAverage
@onready var animal_food_preference_range_label : Label = $Control/PanelContainer/MarginContainer/VBox_Statistics/FoodPreferenceRange

@onready var animal_stealth_avg_label : Label = $Control/PanelContainer/MarginContainer/VBox_Statistics/StealthAverage
@onready var animal_stealth_range_label : Label = $Control/PanelContainer/MarginContainer/VBox_Statistics/StealthRange

@onready var animal_detection_avg_label : Label = $Control/PanelContainer/MarginContainer/VBox_Statistics/DetectionAverage
@onready var animal_detection_range_label : Label = $Control/PanelContainer/MarginContainer/VBox_Statistics/DetectionRange

@onready var animal_nutrition_avg_label : Label = $Control/PanelContainer/MarginContainer/VBox_Statistics/NutritionAverage
@onready var animal_hydration_avg_label : Label = $Control/PanelContainer/MarginContainer/VBox_Statistics/HydrationAverage
@onready var animal_ready_to_mate_avg_label : Label = $Control/PanelContainer/MarginContainer/VBox_Statistics/ReadyToMateAverage

@onready var animal_deaths_starvation_label: Label = $Control/PanelContainer/MarginContainer/VBox_Statistics/DeathsStarvation
@onready var animal_deaths_dehydration_label: Label = $Control/PanelContainer/MarginContainer/VBox_Statistics/DeathsDehydration
@onready var animal_deaths_age_label: Label = $Control/PanelContainer/MarginContainer/VBox_Statistics/DeathsAge
@onready var animal_deaths_predation_label: Label = $Control/PanelContainer/MarginContainer/VBox_Statistics/DeathsPredation

@onready var nutrition_from_meat_label: Label = $Control/PanelContainer/MarginContainer/VBox_Statistics/NutritionFromMeat
@onready var nutrition_from_plants_label: Label = $Control/PanelContainer/MarginContainer/VBox_Statistics/NutritionFromPlants

func update_stats():
    var stats = World.simulation.get_animal_statistics()

    world_age_label.text = "World Age: %d" % World.game_steps
    animal_count_label.text = "Animal Count: %d" % stats.animal_count

    animal_speed_avg_label.text = "Speed Average: %.2f" % stats.speed_avg
    animal_speed_range_label.text = "Speed Range: %.2f - %.2f" % [stats.speed_range.x, stats.speed_range.y]

    animal_mate_rate_avg_label.text = "MatingRate Average: %.2f" % stats.mating_rate_avg
    animal_mate_rate_range_label.text = "MatingRate Range: %.2f - %.2f" % [stats.mating_rate_range.x, stats.mating_rate_range.y]

    animal_food_preference_avg_label.text = "FoodPref Average: %.2f" % stats.food_preference_avg
    animal_food_preference_range_label.text = "FoodPref Range: %.2f - %.2f" % [stats.food_preference_range.x, stats.food_preference_range.y]

    animal_size_avg_label.text = "Average Size: %.2f" % stats.size_avg
    animal_size_range_label.text = "Size Range: %.2f - %.2f" % [stats.size_range.x, stats.size_range.y]

    animal_stealth_avg_label.text = "Stealth Average: %.2f" % stats.stealth_avg
    animal_stealth_range_label.text = "Stealth Range: %.2f - %.2f" % [stats.stealth_range.x, stats.stealth_range.y]

    animal_detection_avg_label.text = "Detection Average: %.2f" % stats.detection_avg
    animal_detection_range_label.text = "Detection Range: %.2f - %.2f" % [stats.detection_range.x, stats.detection_range.y]

    animal_nutrition_avg_label.text = "Nutrition Average: %.2f" % stats.animal_nutrition_avg
    animal_hydration_avg_label.text = "Hydration Average: %.2f" % stats.animal_hydration_avg
    animal_ready_to_mate_avg_label.text = "Ready to mate Average: %.2f" % stats.animal_ready_to_mate_avg

    animal_deaths_starvation_label.text = "Deaths Starvation: %d" % stats.animal_deaths_starvation
    animal_deaths_dehydration_label.text = "Deaths Dehydration: %d" % stats.animal_deaths_dehydration
    animal_deaths_age_label.text = "Deaths Age: %d" % stats.animal_deaths_age
    animal_deaths_predation_label.text = "Deaths Predation: %d" % stats.animal_deaths_predation

    nutrition_from_meat_label.text = "Nutrition Meat: %.2f" % stats.nutrition_from_meat
    nutrition_from_plants_label.text = "Nutrition Plants: %.2f" % stats.nutrition_from_plants
