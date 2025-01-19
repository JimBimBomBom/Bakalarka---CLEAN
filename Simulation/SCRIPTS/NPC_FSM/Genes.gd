class_name Animal_Genes

#Physical
var size : float            
var speed : float

#Diet
# Herbivore from <0, 0.25>
# Omnivore from <0.25, 0.75>
# Carnivore from <0.75, 1>
var food_prefference : float # <0, 1> where 0 -> pure herbivore, 1 -> pure carnivore

#Reproduction
var mating_rate : float     # <0, 1> where 0 -> never mates, 1 -> always mates

#Senses
# TODO: stealth vs detection, fight vs flight, etc.

func generate_genes():
    size = randf_range(0, 1)
    speed = randf_range(0, 1)
    food_prefference = randf_range(0, 1)
    mating_rate = randf_range(0, 1)

func set_genes(set_size : float, set_speed : float, set_food_prefference : float, set_mating_rate : float):
    self.size = set_size
    self.speed = set_speed
    self.food_prefference = set_food_prefference
    self.mating_rate = set_mating_rate

func pass_down_genes(parent_1 : Animal_Genes, parent_2 : Animal_Genes):
    size = extract_gene(parent_1.size, parent_2.size)
    speed = extract_gene(parent_1.speed, parent_2.speed)
    food_prefference = extract_gene(parent_1.food_prefference, parent_2.food_prefference)
    mating_rate = extract_gene(parent_1.mating_rate, parent_2.mating_rate)

func extract_gene(parent_1: float, parent_2: float) -> float: # only for float genes -> need new func for other types
    var from_parent = randi_range(0, 1) # 0 -> parent_1 || 1 -> parent_2
    var mut = randf_range(0, 1)
    var result
    if from_parent:
        result = parent_2
    else:
        result = parent_1
    if mut < World.mutation_prob:
        result = randf_range(-World.mutation_half_range, World.mutation_half_range) + result # if mutation occurs it can influence a gene by up to 5%.. also cant be a negative value
        result = clamp(result, 0, 1)
        
    return result
