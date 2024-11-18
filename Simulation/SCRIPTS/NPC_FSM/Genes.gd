class_name Animal_Genes

#Physical
var size : float            # influences mass, max_velocity, combat_ability and insulation
var musculature : float     # influences max_velocity, and combat_ability 
var skin_thickness : float  # influences insulation, and combat_ability
var metabolic_rate : float  # signifies bonus rate of nutrient conversion

var combat_strength : float # influences combat_ability

#Senses
var sense_range : float # used for food_crop/animal detection
var cadaver_detection_range : float # allows animals to detect cadavers from a distance

#Behavioral
var aggression : float
var separation : float
var cohesion : float
var alignment : float

func generate_genes():
    size = randf_range(0, 1)
    musculature = randf_range(0, 1)
    skin_thickness = randf_range(0, 1)
    metabolic_rate = randf_range(0, 1)
    combat_strength = randf_range(0, 1)

    sense_range = randf_range(80, 180)

    aggression = randf_range(0, 1)
    separation = randf_range(0, 1)
    cohesion = randf_range(0, 1)
    alignment = randf_range(0, 1)

func pass_down_genes(parent_1 : Animal_Genes, parent_2 : Animal_Genes):
    size = extract_gene(parent_1.size, parent_2.size)
    musculature = extract_gene(parent_1.musculature, parent_2.musculature)
    skin_thickness = extract_gene(parent_1.skin_thickness, parent_2.skin_thickness)
    metabolic_rate = extract_gene(parent_1.metabolic_rate, parent_2.metabolic_rate)
    combat_strength = extract_gene(parent_1.combat_strength, parent_2.combat_strength)

    sense_range = extract_gene(parent_1.sense_range, parent_2.sense_range)

    aggression = extract_gene(parent_1.aggression, parent_2.aggression)
    separation = extract_gene(parent_1.separation, parent_2.separation)
    cohesion = extract_gene(parent_1.cohesion, parent_2.cohesion)
    alignment = extract_gene(parent_1.alignment, parent_2.alignment)

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
