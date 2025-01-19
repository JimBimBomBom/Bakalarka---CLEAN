class_name Tile_Properties

var index : Vector2i
var biome : World.Biome_Type
var animal_ids : Array
var scent_trails : Array

# NOTE: determines regrowth rate of plants, influences animals?
var temperature : float
var moisture : float

var plant_matter : float
var plant_matter_gain
var max_plant_matter : float

# add spoilage
var meat_in_rounds : Array
var total_meat : float
var meat_spoil_rate : float

var hydration : float
var max_hydration : float
