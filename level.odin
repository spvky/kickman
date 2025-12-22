package main

build_level :: proc() {
	append(
		&world.level_collision,
		Level_Collider{min = {100, 150}, max = {300, 200}, flags = {.Standable}},
	)
}
