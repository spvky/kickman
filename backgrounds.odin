package main

import "core:fmt"
import rl "vendor:raylib"

origin: Vec2

draw_paralax_layers :: proc() {
	dimensions := assets.room_dimensions[world.current_room]
	offset := Vec2{f32(SCREEN_WIDTH) / 2, f32(SCREEN_HEIGHT) / 2}
	target := world.camera.target
	position := offset + target
	textures := assets.room_background_textures[world.current_room.region_tag]
	for texture, i in textures {
		fmt.printfln("Origin %v", origin)
		n := f32(i)
		shift := (-(dimensions / 2) + position) * n
		origin = Vec2{320, 160}
		// origin := Vec2{0, 0}
		source := rl.Rectangle{0, 0, 640, 320}
		dest := rl.Rectangle{shift.x, shift.y, 640, 320}
		// dest := rl.Rectangle {player.translation}
		rl.DrawTexturePro(texture, source, dest, origin, 0, rl.WHITE)

		delta := rl.GetFrameTime()

		if rl.IsKeyDown(.LEFT) {
			origin.x -= delta * 10
		}
		if rl.IsKeyDown(.RIGHT) {
			origin.x += delta * 10
		}
		if rl.IsKeyDown(.UP) {
			origin.y -= delta * 10
		}
		if rl.IsKeyDown(.DOWN) {
			origin.y += delta * 10
		}
	}
}
