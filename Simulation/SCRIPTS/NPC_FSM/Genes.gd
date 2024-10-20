class_name Animal_Genes

#Physical
var inteligence : float
var size : float
var musculature : float
var agility : float
var metabolic_rate : float
var offense : float

#Temperature
# NOTE : not used atm
var ideal_temperature : float
var ideal_temperature_range : float

#Sexual
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
	inteligence = randf_range(0, 1)
	size = randf_range(0, 1)
	musculature = randf_range(0, 1)
	agility = randf_range(0, 1)
	metabolic_rate = randf_range(0, 1)
	offense = randf_range(0, 1)
	
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
	inteligence = World.extract_gene(parent_1.inteligence, parent_2.inteligence)
	size = World.extract_gene(parent_1.size, parent_2.size)
	musculature = World.extract_gene(parent_1.musculature, parent_2.musculature)
	agility = World.extract_gene(parent_1.agility, parent_2.agility)
	metabolic_rate = World.extract_gene(parent_1.metabolic_rate, parent_2.metabolic_rate)
	offense = World.extract_gene(parent_1.offense, parent_2.offense)

	num_of_offspring = parent_1.num_of_offspring

	sense_range = World.extract_gene(parent_1.sense_range, parent_2.sense_range)
	sense_acuity = World.extract_gene(parent_1.sense_acuity, parent_2.sense_acuity)
	field_of_view_half = World.extract_gene(parent_1.field_of_view_half, parent_2.field_of_view_half)
	vision_range = World.extract_gene(parent_1.vision_range, parent_2.vision_range)

	aggressiveness = World.extract_gene(parent_1.aggressiveness, parent_2.aggressiveness)
	separation_mult = World.extract_gene(parent_1.separation_mult, parent_2.separation_mult)
	cohesion_mult = World.extract_gene(parent_1.cohesion_mult, parent_2.cohesion_mult)
	alignment_mult = World.extract_gene(parent_1.alignment_mult, parent_2.alignment_mult)
