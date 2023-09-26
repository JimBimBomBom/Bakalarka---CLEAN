class_name Animal_Genes

#Physical
var gender : World.Gender
var size : float
var musculature : float
var agility : float
var metabolic_rate : float
var offense : float

#Sexual
var male_sex_cooldown : float # redundant atm
var pregnancy_duration : float
var num_of_offspring : int

#Senses
var sense_range : float
var sense_acuity : float
var field_of_view_half : float
var vision_range : float

#Behavioral
var aggressiveness : float
var separation_mult : float
var cohesion_mult : float
var alignment_mult : float

func generate_genes():
	if randi_range(0, 1):
		gender = World.Gender.MALE
	else:
		gender = World.Gender.FEMALE
	size = randf_range(0, 1)
	musculature = randf_range(0, 1)
	agility = randf_range(0, 1)
	metabolic_rate = randf_range(0, 1)
	offense = randf_range(0, 1)
	
	male_sex_cooldown = World.hours_in_day
	pregnancy_duration = 2 * World.hours_in_day
	num_of_offspring = 1

	sense_range = randf_range(80, 180)
	sense_acuity = randf_range(0, 1)
	field_of_view_half = randf_range(30, 70)
	vision_range = randf_range(70, 140)

	aggressiveness = randf_range(0, 1)
	separation_mult = randf_range(0, 1)
	cohesion_mult = randf_range(0, 1)
	alignment_mult = randf_range(0, 1)

func pass_down_genes(parent_1 : Animal_Genes, parent_2 : Animal_Genes):
	if randi_range(0, 1):
		gender = parent_1.gender
	else:
		gender = parent_2.gender
	size = World.extract_gene(parent_1.size, parent_2.size)
	musculature = World.extract_gene(parent_1.musculature, parent_2.musculature)
	agility = World.extract_gene(parent_1.agility, parent_2.agility)
	metabolic_rate = World.extract_gene(parent_1.metabolic_rate, parent_2.metabolic_rate)
	offense = World.extract_gene(parent_1.offense, parent_2.offense)

	male_sex_cooldown = World.extract_gene(parent_1.male_sex_cooldown, parent_2.male_sex_cooldown)
	pregnancy_duration = World.extract_gene(parent_1.pregnancy_duration, parent_2.pregnancy_duration)
	num_of_offspring = parent_1.num_of_offspring

	sense_range = World.extract_gene(parent_1.sense_range, parent_2.sense_range)
	sense_acuity = World.extract_gene(parent_1.sense_acuity, parent_2.sense_acuity)
	field_of_view_half = World.extract_gene(parent_1.field_of_view_half, parent_2.field_of_view_half)
	vision_range = World.extract_gene(parent_1.vision_range, parent_2.vision_range)

	aggressiveness = World.extract_gene(parent_1.aggressiveness, parent_2.aggressiveness)
	separation_mult = World.extract_gene(parent_1.separation_mult, parent_2.separation_mult)
	cohesion_mult = World.extract_gene(parent_1.cohesion_mult, parent_2.cohesion_mult)
	alignment_mult = World.extract_gene(parent_1.alignment_mult, parent_2.alignment_mult)
