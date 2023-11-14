class_name Animal_Genes

#Physical
var gender : World.Gender
var inteligence : float
var size : float
var musculature : float
var agility : float
var metabolic_rate : float
var offense : float

#Temperature
var ideal_temperature : float
var ideal_temperature_range : float

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
	inteligence = randf_range(0, 1)
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

func pass_down_genes(mother : Animal_Genes, father : Animal_Genes):
	if randi_range(0, 1):
		gender = mother.gender
	else:
		gender = father.gender
	inteligence = World.extract_gene(mother.inteligence, father.inteligence)
	size = World.extract_gene(mother.size, father.size)
	musculature = World.extract_gene(mother.musculature, father.musculature)
	agility = World.extract_gene(mother.agility, father.agility)
	metabolic_rate = World.extract_gene(mother.metabolic_rate, father.metabolic_rate)
	offense = World.extract_gene(mother.offense, father.offense)

	male_sex_cooldown = World.extract_gene(mother.male_sex_cooldown, father.male_sex_cooldown)
	pregnancy_duration = World.extract_gene(mother.pregnancy_duration, father.pregnancy_duration)
	num_of_offspring = mother.num_of_offspring

	sense_range = World.extract_gene(mother.sense_range, father.sense_range)
	sense_acuity = World.extract_gene(mother.sense_acuity, father.sense_acuity)
	field_of_view_half = World.extract_gene(mother.field_of_view_half, father.field_of_view_half)
	vision_range = World.extract_gene(mother.vision_range, father.vision_range)

	aggressiveness = World.extract_gene(mother.aggressiveness, father.aggressiveness)
	separation_mult = World.extract_gene(mother.separation_mult, father.separation_mult)
	cohesion_mult = World.extract_gene(mother.cohesion_mult, father.cohesion_mult)
	alignment_mult = World.extract_gene(mother.alignment_mult, father.alignment_mult)
