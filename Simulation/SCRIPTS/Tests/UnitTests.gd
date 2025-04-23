extends Node

func test_axial_coords():
    var offset = Vector2i(3, 4)
    var offset_to_axial = World.offset_to_axial(offset)
    var axial_to_offset = World.axial_to_offset(offset_to_axial)
    assert(axial_to_offset == offset, "Offset to axial conversion failed")

    var offset2 = Vector2i(2, 2)
    var offset_to_axial2 = World.offset_to_axial(offset2)
    assert(offset_to_axial2 == Vector2i(1, 2), "Offset to axial conversion failed")

func test_offset_distance():
    var offset1 = Vector2i(3, 4)
    var offset2 = Vector2i(3, 5)
    var offset3 = Vector2i(4, 4)
    var offset4 = Vector2i(4, 5)
    assert(World.offset_distance(offset1, offset2) == 1, "Offset distance failed")
    assert(World.offset_distance(offset1, offset3) == 1, "Offset distance failed")
    assert(World.offset_distance(offset1, offset4) == 2, "Offset distance failed")

func test_get_neighbouring_tiles():
    var tile_pos = Vector2i(3, 4)
    var neighbours = World.get_neighbouring_tiles(tile_pos)
    assert(neighbours.size() == 6, "Neighbouring tiles count failed")

    var tile_pos2 = Vector2i(0, 0)
    var neighbours2 = World.get_neighbouring_tiles(tile_pos2)
    assert(neighbours2.size() == 2, "Neighbouring tiles count failed")

func test_get_neighbouring_tiles_in_range():
    var tile_pos = Vector2i(3, 4)
    var neighbours = World.get_neighbouring_tiles_in_range(tile_pos, 1)
    assert(neighbours.size() == 6, "Neighbouring tiles count failed")
    var neighbours3 = World.get_neighbouring_tiles_in_range(tile_pos, 2)
    assert(neighbours3.size() == (6 + 12), "Neighbouring tiles count failed")

func test_get_neighbouring_tiles_in_range_indexes():
    var tile_pos = Vector2i(3, 4)
    var neighbours = World.get_neighbouring_tiles_in_range(tile_pos, 1)
    var expected_neighbours = [
        Vector2i(2, 4),
        Vector2i(4, 4),
        Vector2i(3, 3),
        Vector2i(2, 3),
        Vector2i(3, 5),
        Vector2i(4, 5),
    ]
    for i in range(neighbours.size()):
        assert(neighbours[i] == expected_neighbours[i], "Neighbouring tiles indexes failed")

    var tile_pos2 = Vector2i(0, 0)
    var neighbours2 = World.get_neighbouring_tiles_in_range(tile_pos2, 1)
    var expected_neighbours2 = [
        Vector2i(0, 1),
        Vector2i(1, 0),
    ]
    for i in range(neighbours2.size()):
        assert(neighbours2[i] == expected_neighbours2[i], "Neighbouring tiles indexes failed")
    
    var tile_pos3 = Vector2i(0, 0)
    var neighbours3 = World.get_neighbouring_tiles_in_range(tile_pos3, 2)
    var expected_neighbours3 = [
        Vector2i(0, 1),
        Vector2i(1, 0),
        Vector2i(1, 1),
        Vector2i(0, 2),
        Vector2i(2, 0),
        Vector2i(1, 2),
    ]
    for i in range(neighbours3.size()):
        assert(neighbours3[i] == expected_neighbours3[i], "Neighbouring tiles indexes failed")

    var tile_pos4 = Vector2i(0, 0)
    var neighbours4 = World.get_neighbouring_tiles_in_range(tile_pos4, 3)
    var expected_neighbours4 = [
        Vector2i(0, 1),
        Vector2i(1, 0),
        Vector2i(1, 1),
        Vector2i(0, 2),
        Vector2i(2, 0),
        Vector2i(1, 2),
        Vector2i(3, 0),
        Vector2i(2, 1),
        Vector2i(2, 2),
        Vector2i(1, 3),
        Vector2i(0, 3),
    ]

func run_tests():
    print("Running unit tests")
    test_axial_coords()
    test_offset_distance()
    test_get_neighbouring_tiles()
    test_get_neighbouring_tiles_in_range()
    print("Unit tests successfully finished")
