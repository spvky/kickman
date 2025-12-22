package main

import rl "vendor:raylib"

WINDOW_WIDTH: i32 = 1920
WINDOW_HEIGHT: i32 = 1080
SCREEN_WIDTH :: 400 //25x14 16 pixel tiles
SCREEN_HEIGHT :: 224

Assets :: struct {
	gameplay_texture: rl.RenderTexture,
}

assets: Assets

init_assets :: proc() {
	assets.gameplay_texture = rl.LoadRenderTexture(WINDOW_WIDTH, WINDOW_HEIGHT)
}
