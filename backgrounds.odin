package main

import "core:fmt"
import rl "vendor:raylib"


draw_paralax_layers :: proc() {
	extents := assets.room_dimensions[world.current_room]
	width_units := (extents.x / 400) + 1
	offset := Vec2{f32(SCREEN_WIDTH) / 2, f32(SCREEN_HEIGHT) / 2}
	target := world.camera.target
	position := offset + target
	textures := assets.room_background_textures[world.current_room.region_tag]
	center := extents / 2
	for texture, i in textures {
		n := f32(i)
		if i != 0 {
			center_dif := -(center.x / 2) + position.x
			position.x -= center_dif * 1 / (4 / n)
		}
		origin := Vec2{320, 160}
		source := rl.Rectangle{0, 0, 320 * width_units, 320}
		dest := rl.Rectangle{position.x - 320, position.y, 320 * width_units, 320}
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
