package main

import "base:runtime"
import "core:log"
import rl "vendor:raylib"

main :: proc() {
	context.logger = log.create_console_logger(
		opt = runtime.Logger_Options{.Level, .Short_File_Path, .Line},
	)
	game_init()
	for !rl.WindowShouldClose() {
		game_update()
	}
}
