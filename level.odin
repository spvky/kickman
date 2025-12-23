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
