extends Animal

class_name Herbivore

var detected_crops: Array[Food_Crop] = []

func herbivore_fsm(delta : float):
    var dangerous_animals: Array[Animal] = filter_animals_by_danger()
    set_base_state(dangerous_animals)

    match animal_state:
        Animal_Base_States.FLEEING:
            consumption_state = Consumption_State.SEEKING # if an animal was eating/drinking when a danger entered its area if should not remain in consuming state
            set_next_move(get_flee_dir(dangerous_animals))
        Animal_Base_States.HUNGRY:
            if not detected_crops.is_empty():
                var selected_crop = get_closest_crop()
                herbivore_eat(selected_crop, delta)
            else:
                set_next_move(wander())
        Animal_Base_States.THIRSTY:
            var hydration_in_range: Array[World.Tile_Properties] = hydration_in_range()
            if not hydration_in_range.is_empty():
                var selected_water_tile = select_hydration_tile(hydration_in_range)
                animal_hydrate(selected_water_tile, delta)
            else:
                if last_visited_water_tile:
                    animal_hydrate(last_visited_water_tile, delta) # TODO: make this into wandering with a bias
                else:
                    set_next_move(wander())
        Animal_Base_States.SATED:
            if can_have_sex and energy_norm >= World.reproduction_energy_cost and not detected_animals.is_empty():
                var potential_mates = select_potential_mates(detected_animals, animal_type)
                if not potential_mates.is_empty():
                    var mate = select_mating_partner(potential_mates)
                    reproduce_with_animal(mate) # so far the only heuristic is viscinity
                    return
            set_next_move(wander())

func set_base_state(dangerous_animals: Array[Animal]):
    if energy <= 0: # or health <= 0:
        kill_animal()
    elif not dangerous_animals.is_empty():
        animal_state = Animal_Base_States.FLEEING
    elif animal_state == Animal_Base_States.SATED:
        if nutrition_norm < seek_nutrition_norm and nutrition_norm <= hydration_norm:
            animal_state = Animal_Base_States.HUNGRY
        elif hydration_norm < seek_hydration_norm and hydration_norm <= nutrition_norm:
            animal_state = Animal_Base_States.THIRSTY
    elif animal_state == Animal_Base_States.HUNGRY:
        if nutrition_norm > seek_nutrition_norm and hydration_norm < seek_hydration_norm:
            animal_state = Animal_Base_States.THIRSTY
        elif nutrition_norm >= nutrition_satisfied_norm:
            animal_state = Animal_Base_States.SATED
    elif animal_state == Animal_Base_States.THIRSTY:
        if hydration_norm >= hydration_satisfied_norm:
            animal_state = Animal_Base_States.SATED
    else: # animal_state == Animal_Base_States.FLEEING -> if no dangerous animals are in sight, and we are not hungry/thirsty, we are sated
        animal_state = Animal_Base_States.SATED

func herbivore_eat(crop, delta: float):
    match consumption_state:
        Consumption_State.SEEKING:
            set_next_move(seek(crop.position))
            if position.distance_to(crop.position) < 10:
                consumption_state = Consumption_State.CONSUMING
        Consumption_State.CONSUMING:
            if position.distance_to(crop.position) >= 10:
                consumption_state = Consumption_State.SEEKING
            else:
                stop_animal()
                eat_crop(crop)
                consumption_state = Consumption_State.SEEKING

func get_closest_crop():
    var closest: Food_Crop = detected_crops[0]
    var closest_dist = position.distance_to(closest.position) # detected crops is not empty
    for crop in detected_crops:
        var crop_dist = position.distance_to(crop.position)
        if crop_dist < closest_dist:
            closest_dist = crop_dist
            closest = crop
    return closest

func eat_crop(crop):
    nutrition += crop.yield_value
    crop.be_eaten()
    
func spawn_herbivore(pos, parent_1, parent_2):
    spawn_animal(pos, World.Vore_Type.HERBIVORE, parent_1, parent_2)
    animal_type = Animal_Types.DEER

func construct_herbivore(pos):
    construct_animal(pos, World.Vore_Type.HERBIVORE)
    animal_type = Animal_Types.DEER

func _physics_process(delta: float):
    do_timers(delta) # each physics stedp -> only step we use, increment timers and execute if needed
    if animal_state == Animal_Base_States.DEAD:
        return
    update_animal_resources(delta)
    herbivore_fsm(delta)
    do_move(delta)

func _on_Area2D_food_crop_entered(body):
    var body_parent = body.get_parent()
    if body_parent is Food_Crop:
        detected_crops.append(body_parent)

func _on_Area2D_food_crop_exited(body):
    var body_parent = body.get_parent()
    if body_parent is Food_Crop:
        detected_crops.erase(body_parent)

func _ready():
    change_age_timer = SimulationTimer.new()
    change_age_timer.trigger_time = change_age_period
    change_age_timer.active = true
    change_age_timer.timer_triggered.connect(_on_change_age_timer_timeout)

    sex_cooldown_timer = SimulationTimer.new()
    sex_cooldown_timer.trigger_time = sex_cooldown
    sex_cooldown_timer.active = true
    sex_cooldown_timer.timer_triggered.connect(_on_sex_cooldown_timeout)

    cadaver_timer = SimulationTimer.new()
    cadaver_timer.trigger_time = World.corpse_time
    cadaver_timer.active = false
    cadaver_timer.timer_triggered.connect(free_cadaver)

    var animal_detector = find_child("Area_Detection")
    animal_detector.body_entered.connect(_on_Area2D_animal_entered)
    animal_detector.body_exited.connect(_on_Area2D_animal_exited)

    # Herbivores will detect food crops using collision with crop's Area2D
    animal_detector.area_entered.connect(_on_Area2D_food_crop_entered)
    animal_detector.area_exited.connect(_on_Area2D_food_crop_exited)

    var detection_radius = animal_detector.find_child("Detection_Radius")
    detection_radius.shape = detection_radius.shape.duplicate() # NOTE: without this specification, this NODE would be shared between instances -> no individualized radius
    detection_radius.shape.radius = genes.sense_range
