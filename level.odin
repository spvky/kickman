package main

import "ldtk"


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
	Tutorial,
}

Room :: struct {
	// Id field should go here to handle
	room_collision: [dynamic]Level_Collider,
	width:          int,
	height:         int,
}

Region :: struct {
	name:  string,
	rooms: [dynamic]Room,
}
