package main

import l "core:math/linalg"

camera_follow_player :: proc() {
	extents := assets.room_dimensions[world.current_room]
	screen := Vec2{f32(SCREEN_WIDTH), f32(SCREEN_HEIGHT)}
	min: Vec2
	offset := Vec2{f32(SCREEN_WIDTH) / 2, f32(SCREEN_HEIGHT) / 2}
	max := extents - screen

	camera_pos := l.clamp(world.player.translation - offset, min, max)
	world.camera.target = camera_pos
}
