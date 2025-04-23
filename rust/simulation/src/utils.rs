use godot::prelude::Vector2i; // Assuming using gdext's Vector2i

pub fn between(val: i32, start: i32, end: i32) -> bool {
    val >= start && val <= end
}

pub fn axial_distance_inline(a: Vector2i, b: Vector2i) -> i32 {
    ((a.x - b.x).abs() + (a.x + a.y - b.x - b.y).abs() + (a.y - b.y).abs()) / 2
}

pub fn offset_to_axial(pos: Vector2i) -> Vector2i {
    let q = pos.x - (pos.y - (pos.y & 1)) / 2;
    let r = pos.y;
    Vector2i::new(q, r)
}

pub fn axial_to_offset(pos: Vector2i) -> Vector2i {
    let x = pos.x + (pos.y - (pos.y & 1)) / 2;
    let y = pos.y;
    Vector2i::new(x, y)
}

pub fn offset_distance(a: Vector2i, b: Vector2i) -> i32 {
    let ac = offset_to_axial(a);
    let bc = offset_to_axial(b);
    axial_distance_inline(ac, bc)
}

 pub fn get_neighbouring_tiles_in_range(
     tile_pos: Vector2i,
     tile_range: i32,
     world_width: i32,
     world_height: i32,
 ) -> Vec<Vector2i> {
     let mut neighbours: Vec<Vector2i> = Vec::new();
     for x in -tile_range..=tile_range {
         for y in -tile_range..=tile_range {
             let pos = Vector2i::new(tile_pos.x + x, tile_pos.y + y);
             if pos == tile_pos { continue; } // Skip self immediately

             if between(pos.x, 0, world_width - 1)
                 && between(pos.y, 0, world_height - 1)
                 && offset_distance(tile_pos, pos) <= tile_range {
                 neighbours.push(pos);
             }
         }
     }
     // No need to erase self if skipped in loop
     neighbours
 }

pub fn get_neighbouring_tiles(
    tile_pos: Vector2i,
    world_width: i32,
    world_height: i32,
) -> Vec<Vector2i> {
    get_neighbouring_tiles_in_range(tile_pos, 1, world_width, world_height)
}
