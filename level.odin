package main


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

Region :: struct {
	tag: Region_Tag,
}

Room_Transition :: struct {
	tag:                 Room_Tag,
	transition_position: [2]f32,
	min:                 [2]f32,
	max:                 [2]f32,
}
