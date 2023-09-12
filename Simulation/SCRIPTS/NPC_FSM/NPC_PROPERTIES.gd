extends Npc_Class

class_name Npc_Properties_Class

#var senses : Senses_Class
# var behaviour : Behaviour_Class 
#Basic characteristics
var vore_type : World.Vore_Type
var curr_health : int
var max_health : int
var attack_damage : int
var attack_range : int
var curr_energy_level : float
var max_energy_level : float
var mass : int
var corpse_max_timer : float
#Resources
var curr_hunger : float
var max_hunger : float
var curr_hunger_norm : float
var seek_nutrition_threshold : float
var curr_hydration : float
var max_hydration : float
var curr_hydration_norm : float
var seek_hydration_threshold : float
#Herd behaviour -> or its' opposite
var separation_radius : int
var separation_mult : float
var cohesion_radius : int
var cohesion_mult : float
var alignment_radius : int
var alignment_mult : float

#Senses
var sense_range : float
#Sight
var sight_range : float
var field_of_view_half : float
var night_vision_acuity : float # DECIDE -> if it wasn't prefferable to only look at the day.. as in no night
var day_vision_acuity : float
#Hearing
var hearing_range : float
var max_hearing_range : float
var hearing_while_consuming : float


#Sexual
var gender : World.Gender
var pregnancy_period : float = 3
var is_pregnant : bool = false
var pregnancy_penalty : float = 0.8
var reproduced_recently : bool = false
var sexual_partner : Animal
# TODO make pregnancy affect the animals behaviour/locomotion/energy_consumption

func set_properties(type, mass_, max_health_, attack_damage_, attack_range_, max_energy_level_, max_hunger_, max_hydration_,
						sight_range_, field_of_view_half_, night_vision_acuity_, day_vision_acuity_, hearing_range_, hearing_while_consuming_,
						separation_mult_, separation_radius_, cohesion_mult_, cohesion_radius_, alignment_mult_, alignment_radius_,
						gender_):
	vore_type = type
	max_health = max_health_
	curr_health = max_health
	attack_damage = attack_damage_
	attack_range = attack_range_
	max_energy_level = max_energy_level_
	curr_energy_level = max_energy_level
	mass = mass_
	corpse_max_timer = 10 #hardset for now

	max_hunger = max_hunger_
	curr_hunger = randf_range(0, max_hunger/2)
	seek_nutrition_threshold = 0.7 #hardset for now
	max_hydration = max_hydration_
	curr_hydration = randf_range(max_hydration/2, max_hydration)
	seek_hydration_threshold = 0.7 #hardset for now

	sight_range = sight_range_
	field_of_view_half = field_of_view_half_
	night_vision_acuity = night_vision_acuity_
	day_vision_acuity = day_vision_acuity_

	max_hearing_range = hearing_range_
	hearing_range = max_hearing_range
	hearing_while_consuming = hearing_while_consuming_

	sense_range = 200 #hardset for now

	separation_mult = separation_mult_
	separation_radius = separation_radius_
	cohesion_mult = cohesion_mult_
	cohesion_radius = cohesion_radius_
	alignment_mult = alignment_mult_
	alignment_radius = alignment_radius_

	gender = gender_

func properties_generator(type):
	match type:
		World.Vore_Type.HERBIVORE:
			var mass = randi_range(50, 250)
			var max_health = mass
			var attack_damage = mass/10
			var attack_range = 5
			var max_energy_level = mass*100
			var max_hunger = mass
			var max_hydration = mass
			var sight_range = randf_range(100, 400)
			var field_of_view_half = randf_range(20, 60)
			var night_vision_acuity = randf_range(0.1, 0.4)
			var day_vision_acuity = 1

			var hearing_range = randf_range(100, 200)
			var hearing_while_consuming = randf_range(0.1, 1)
			
			var separation_mult = 1.5
			var separation_radius = randi_range(25, 50)
			var cohesion_mult = randf_range(0.5, 0.8)
			var cohesion_radius = randi_range(50, 120)
			var alignment_mult = randf_range(0.4, 1)
			var alignment_radius = randi_range(50, 120)

			var gender_f = randi_range(0, 1)
			var gender = World.Gender.FEMALE
			if gender_f:
				gender = World.Gender.MALE
			set_properties(type, mass, max_health, attack_damage, attack_range, max_energy_level, max_hunger, max_hydration,
										sight_range, field_of_view_half, night_vision_acuity, day_vision_acuity, hearing_range, hearing_while_consuming,
										separation_mult, separation_radius, cohesion_mult, cohesion_radius, alignment_mult, alignment_radius,
										gender)
		World.Vore_Type.CARNIVORE:
			var mass = randi_range(50, 250)
			var max_health = mass
			var attack_damage = mass/5
			var attack_range = 15
			var max_energy_level = mass*100
			var max_hunger = mass
			var max_hydration = mass
			var sight_range = randf_range(200, 600)
			var field_of_view_half = randf_range(30, 60)
			var night_vision_acuity = randf_range(0.3, 0.6)
			var day_vision_acuity = 1

			var hearing_range = randf_range(500, 750)
			var hearing_while_consuming = randf_range(0.1, 1)

			var separation_mult = 1
			var separation_radius = randi_range(70, 95)
			var cohesion_mult = randf_range(0.1, 0.3)
			var cohesion_radius = randi_range(50, 120)
			var alignment_mult = randf_range(0, 0.4)
			var alignment_radius = randi_range(50, 120)

			var gender_f = randi_range(0, 1)
			var gender = World.Gender.FEMALE
			if gender_f:
				gender = World.Gender.MALE
			set_properties(type, mass, max_health, attack_damage, attack_range, max_energy_level, max_hunger, max_hydration,
										sight_range, field_of_view_half, night_vision_acuity, day_vision_acuity, hearing_range, hearing_while_consuming,
										separation_mult, separation_radius, cohesion_mult, cohesion_radius, alignment_mult, alignment_radius,
										gender)



func set_animal_properties(type, parent_1, parent_2):
	var mass = World.extract_gene(parent_1.mass, parent_2.mass)
	var max_health = mass
	var attack_damage = mass/10
	var attack_range = 5
	var max_energy_level = mass*100
	var max_hunger = mass
	var max_hydration = mass

	var sight_range = World.extract_gene(parent_1.sight_range, parent_2.sight_range)
	var field_of_view_half = World.extract_gene(parent_1.field_of_view_half, parent_2.field_of_view_half)
	var night_vision_acuity =World.extract_gene(parent_1.night_vision_acuity, parent_2.night_vision_acuity) 
	var day_vision_acuity = World.extract_gene(parent_1.day_vision_acuity, parent_2.day_vision_acuity)

	var hearing_range = World.extract_gene(parent_1.hearing_range, parent_2.hearing_range)
	var hearing_while_consuming = World.extract_gene(parent_1.hearing_while_consuming, parent_2.hearing_while_consuming)
	
	var separation_mult = World.extract_gene(parent_1.separation_mult, parent_2.separation_mult)
	var separation_radius = World.extract_gene(parent_1.separation_radius, parent_2.separation_radius)
	var cohesion_mult = World.extract_gene(parent_1.cohesion_mult, parent_2.cohesion_mult)
	var cohesion_radius = World.extract_gene(parent_1.cohesion_radius, parent_2.cohesion_radius)
	var alignment_mult = World.extract_gene(parent_1.alignment_mult, parent_2.alignment_mult)
	var alignment_radius = World.extract_gene(parent_1.alignment_radius, parent_2.alignment_radius)

	var gender = World.extract_gene(parent_1.gender, parent_2.gender)
	set_properties(type, mass, max_health, attack_damage, attack_range, max_energy_level, max_hunger, max_hydration,
								sight_range, field_of_view_half, night_vision_acuity, day_vision_acuity, hearing_range, hearing_while_consuming,
								separation_mult, separation_radius, cohesion_mult, cohesion_radius, alignment_mult, alignment_radius,
								gender)
