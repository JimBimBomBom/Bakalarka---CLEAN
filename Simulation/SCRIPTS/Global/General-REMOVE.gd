# func between(val, start, end):
#     if start <= val and val <= end:
#         return true
#     return false

# func axial_distance_inline(a, b):
#     return (abs(a.x - b.x) + abs(a.x + a.y - b.x - b.y) + abs(a.y - b.y)) / 2

# func offset_to_axial(pos):
#     var q = pos.x - (pos.y - (pos.y&1)) / 2
#     var r = pos.y
#     return Vector2i(q, r)

# func axial_to_offset(pos):
#     var x = pos.x + (pos.y - (pos.y&1)) / 2
#     var y = pos.y
#     return Vector2i(x, y)

# func offset_distance(a, b):
#     var ac = offset_to_axial(a)
#     var bc = offset_to_axial(b)
#     return axial_distance_inline(ac, bc)

# func get_neighbouring_tiles_in_range(tile_pos : Vector2i, tile_range : int) -> Array[Vector2i]:
#     var neighbours : Array[Vector2i] = []
#     for x in range(-tile_range, tile_range + 1):
#         for y in range(-tile_range, tile_range + 1):
#             var pos = Vector2i(tile_pos.x + x, tile_pos.y + y)
#             if between(pos.x, 0, World.sim_params.width - 1) and between(pos.y, 0, World.sim_params.height - 1) and offset_distance(tile_pos, pos) <= tile_range:
#                 neighbours.append(pos)
#     neighbours.erase(tile_pos) # NOTE: remove the current tile from the list of neighbours
#     return neighbours

# func get_neighbouring_tiles(tile_pos: Vector2i):
#     return get_neighbouring_tiles_in_range(tile_pos, 1)

# func age_scent_tracks_on_tile(index):
#     var tile = World.Map.tiles[index]
#     for scent in tile.scent_trails:
#         scent.scent_duration_left -= 1

#     # TODO: could probably be made more efficient. is it worthwhile?
#     for scent_index in range(tile.scent_trails.size() - 1, -1, -1):
#         tile.scent_trails[scent_index].scent_duration_left -= 1
#         if tile.scent_trails[scent_index].scent_duration_left <= 0:
#             tile.scent_trails.remove_at(scent_index)

# func replenish_map():
#     for index in World.Map.tiles.keys():
#         var tile = World.Map.tiles[index]
#         tile.plant_matter += tile.plant_matter_gain
#         if tile.plant_matter > tile.max_plant_matter:
#             tile.plant_matter = tile.max_plant_matter

#         tile.hydration = tile.max_hydration

#         if tile.meat_in_rounds.size() > 0:
#             for meat in tile.meat_in_rounds:
#                 meat.spoils_in -= 1
#             # Meat can only spoil one meat_in_round at a time
#             if tile.meat_in_rounds[-1].spoils_in <= 0:
#                 tile.total_meat -= tile.meat_in_rounds[-1].amount
#                 tile.meat_in_rounds.pop_back()
        
#         if tile.scent_trails.size() > 0:
#             age_scent_tracks_on_tile(index)
