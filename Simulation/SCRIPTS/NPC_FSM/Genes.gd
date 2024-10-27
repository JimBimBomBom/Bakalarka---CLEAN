class_name Animal_Genes

#Physical
var size : float
var musculature : float
var agility : float
var metabolic_rate : float
var offense : float

#Temperature
# var ideal_temperature : float
# var ideal_temperature_range : float

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
    size = randf_range(0, 1)
    musculature = randf_range(0, 1)
    agility = randf_range(0, 1)
    metabolic_rate = randf_range(0, 1)
    offense = randf_range(0, 1)

    sense_range = randf_range(80, 180)
    sense_acuity = randf_range(0, 1)
    field_of_view_half = randf_range(30, 70)
    vision_range = randf_range(70, 140)

func pass_down_genes(parent_1 : Animal_Genes, parent_2 : Animal_Genes):
    size = extract_gene(parent_1.size, parent_2.size)
    musculature = extract_gene(parent_1.musculature, parent_2.musculature)
    agility = extract_gene(parent_1.agility, parent_2.agility)
    metabolic_rate = extract_gene(parent_1.metabolic_rate, parent_2.metabolic_rate)
    offense = extract_gene(parent_1.offense, parent_2.offense)

    sense_range = extract_gene(parent_1.sense_range, parent_2.sense_range)
    sense_acuity = extract_gene(parent_1.sense_acuity, parent_2.sense_acuity)
    field_of_view_half = extract_gene(parent_1.field_of_view_half, parent_2.field_of_view_half)
    vision_range = extract_gene(parent_1.vision_range, parent_2.vision_range)

func extract_gene(parent_1: float, parent_2: float) -> float: # only for float genes -> need new func for other types
    var from_parent = randi_range(0, 1) # 0 -> parent_1 || 1 -> parent_2
    var mut = randf_range(0, 1)
    var result
    if from_parent:
        result = parent_2
    else:
        result = parent_1
    if mut < World.mutation_prob:
        var mut_val = randf_range(-World.mutation_half_range, World.mutation_half_range) * result # if mutation occurs it can influence a gene by up to 5%.. also cant be a negative value
        result = max(0, result + mut_val)
    return result
