package main

import rl "vendor:raylib"

draw_text :: proc() {
	rl.DrawTextEx(assets.font, "Hello Dungeon", {200, 100}, 24, 1, rl.WHITE)
}
