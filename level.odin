package main

import lr "./level_read"
import lw "./level_write"


build_level :: proc() {
	append(
		&world.level_collision,
		Level_Collider{min = {0, 0}, max = {400, 24}, flags = {.Standable}},
	)
	append(
		&world.level_collision,
		Level_Collider{min = {0, 200}, max = {400, 224}, flags = {.Standable}},
	)
	append(
		&world.level_collision,
		Level_Collider{min = {0, 0}, max = {24, 224}, flags = {.Standable}},
	)
	append(
		&world.level_collision,
		Level_Collider{min = {376, 0}, max = {400, 224}, flags = {.Standable}},
	)
}

Room_Tag :: struct {
	region_tag: Region_Tag,
	room_index: u8,
}

Region_Tag :: enum {
	tutorial,
}

Room_Collision :: struct {
	room_collision: [dynamic]Level_Collider,
}

Region :: struct {
	tag: Region_Tag,
}


// load_room :: proc(r: lw.Binary_Room) -> (room: ^Room) {
// 	room.width = r.width
// 	room.height = r.height
// 	collision := make([dynamic]game.Level_Collider, 0, len(r.collision))
// 	for c in r.collision {
// 		level_collider: game.Level_Collider
// 	}

// }
