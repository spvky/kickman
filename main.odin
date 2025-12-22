package main
import rl "vendor:raylib"


main :: proc() {
	game_init()
	for !rl.WindowShouldClose() {
		game_update()
	}
}
