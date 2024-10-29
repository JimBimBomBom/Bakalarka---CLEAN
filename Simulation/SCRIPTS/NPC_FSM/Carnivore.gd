extends Animal

class_name Carnivore

func carnivore_fsm(delta : float):
    var cadavers_in_range : Array[Animal] = get_cadavers()
    set_base_state(cadavers_in_range) # dangerous_animals

    match animal_state:
        Animal_Base_States.EATING:
            if not cadavers_in_range.is_empty():
                var target = select_cadaver(cadavers_in_range)
                carnivore_seek_cadaver(target, delta)
        Animal_Base_States.HUNTING:
            var prey_in_range = filter_animals_by_type(detected_animals, Animal_Types.DEER)
            if not prey_in_range.is_empty():
                var target = select_target(prey_in_range)
                hunt_animal(target, delta)
            elif hydration_norm < seek_hydration_norm: # if no food in sight, seek water
                animal_state = Animal_Base_States.THIRSTY
            else:
                set_next_move(wander())
        Animal_Base_States.THIRSTY:
            var hydration_in_range : Array[World.Tile_Properties] = hydration_in_range()
            if not hydration_in_range.is_empty():
                var water_tile = select_hydration_tile(hydration_in_range)
                animal_hydrate(water_tile, delta)
            else:
                if last_visited_water_tile:
                    animal_hydrate(last_visited_water_tile, delta) #TODO: make this into wandering with a bias
                else:
                    set_next_move(wander()) 
        Animal_Base_States.SATED:
            if can_have_sex and energy_norm >= World.reproduction_energy_cost and not detected_animals.is_empty():
                var potential_mates = select_potential_mates(detected_animals, animal_type)
                if not potential_mates.is_empty():
                    var mate = select_mating_partner(potential_mates)
                    reproduce_with_animal(mate)
                    return
            set_next_move(wander())

func set_base_state(cadavers_in_range : Array[Animal]):
    if energy <= 0: # or health <= 0:
        kill_animal()
    elif not cadavers_in_range.is_empty() and nutrition_norm < nutrition_satisfied_norm: 
        animal_state = Animal_Base_States.EATING
    elif animal_state == Animal_Base_States.SATED:
        if nutrition_norm < seek_nutrition_norm and nutrition_norm <= hydration_norm:
            animal_state = Animal_Base_States.HUNTING
        elif hydration_norm < seek_hydration_norm and hydration_norm <= nutrition_norm:
            animal_state = Animal_Base_States.THIRSTY
    elif animal_state == Animal_Base_States.HUNTING:
        if nutrition_norm > seek_nutrition_norm and hydration_norm < seek_hydration_norm:
            animal_state = Animal_Base_States.THIRSTY
        elif nutrition_norm >= nutrition_satisfied_norm:
            animal_state = Animal_Base_States.SATED
    elif animal_state == Animal_Base_States.THIRSTY:
        if hydration_norm >= hydration_satisfied_norm:
            animal_state = Animal_Base_States.SATED
    else: # if animal_state == Animal_Base_States.EATING
        animal_state = Animal_Base_States.SATED

func carnivore_seek_cadaver(target : Animal, delta : float):
    match consumption_state:
        Consumption_State.SEEKING:
            set_next_move(seek(target.position))
            if position.distance_to(target.position) < 10:
                consumption_state = Consumption_State.CONSUMING
        Consumption_State.CONSUMING: 
            if position.distance_to(target.position) >= 10:
                consumption_state = Consumption_State.SEEKING
            else:
                stop_animal()
                eat_cadaver(target, delta)
                consumption_state = Consumption_State.SEEKING

func hunt_animal(target : Animal, delta : float):
    if consumption_state == Consumption_State.CONSUMING: # after we eat a cadaver/cadaver disappears, we remain in CONSUMING state
        consumption_state = Consumption_State.SEEKING
    match consumption_state:
        Consumption_State.SEEKING:
            set_next_move(seek(target.position))
            if is_target_in_range(target):
                consumption_state = Consumption_State.ATTACKING
        Consumption_State.ATTACKING:
            stop_animal()
            fight(target)
            consumption_state = Consumption_State.SEEKING

func eat_cadaver(target : Animal, delta : float):
    var food_gain = min(target.mass, delta * (genes.size * 10)) # NOTE : placeholder, but an idea is there. large animals eat faster
    nutrition += food_gain
    target.mass -= food_gain
    if target.mass == food_gain:
        target.free_cadaver()

func is_target_in_range(target : Animal) -> bool:
    if position.distance_to(target.position) < 10: #TODO: this is a placeholder
        return true
    return false

func get_stalk_dir(target : Animal) -> Vector2:
    return position.direction_to(target.position + target.curr_velocity).normalized()

func select_cadaver(cadavers_in_range : Array[Animal]) -> Animal:
    var result : Animal = cadavers_in_range[0]
    var curr_best_distance : float = position.distance_to(result.position)
    for cadaver in cadavers_in_range:
        var dist_to_target = position.distance_to(cadaver.position) 
        if dist_to_target < curr_best_distance:
            curr_best_distance = dist_to_target
            result = cadaver
    return result

func select_target(animals_in_range : Array[Animal]) -> Animal:
    var result : Animal = animals_in_range[0]
    var curr_best_distance : float = position.distance_to(result.position)
    for animal in animals_in_range:
        var dist_to_target = position.distance_to(animal.position) 
        if dist_to_target < curr_best_distance:
            curr_best_distance = dist_to_target
            result = animal
    return result

func spawn_carnivore(pos, mother, father):
    spawn_animal(pos, World.Vore_Type.CARNIVORE, mother, father)
    animal_type = Animal_Types.WOLF

func construct_carnivore(pos):
    construct_animal(pos, World.Vore_Type.CARNIVORE)
    animal_type = Animal_Types.WOLF

func _physics_process(delta : float):
    do_timers(delta) # each physics step -> increment timers and execute if needed
    if animal_state == Animal_Base_States.DEAD:
        return
    update_animal_resources(delta)
    carnivore_fsm(delta)
    do_move(delta)

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

    var detection_radius = animal_detector.find_child("Detection_Radius")
    detection_radius.shape = detection_radius.shape.duplicate() # NOTE: without this specification, this NODE would be shared between instances -> no individualized radius
    detection_radius.shape.radius = genes.sense_range
