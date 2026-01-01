package main

import tags "./tags/"


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

Region :: struct {
	tag: tags.Region_Tag,
}

Room_Transition :: struct {
	tag:                 tags.Room_Tag,
	transition_position: [2]f32,
	using aabb:          AABB,
}
