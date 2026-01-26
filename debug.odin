package main

import "core:fmt"
import "core:strings"
import "tags"
import rl "vendor:raylib"

player_debug :: proc() {
	player := world.player
	ball := world.ball
	extents := assets.room_dimensions[world.current_room]

	player_string := fmt.tprintf(
		"Player:\n\tFacing | Running: %v | %v\n\tTranslation: [%.1f,%.1f]\n\tVelocity: [%.1f,%.1f]\n\tKick Angle: %v\n\tState: %v\n\tFlags: %v\n\tTimed Flags: %v\nWall Point: %v\nCam Target: %v\n\tExtents: %v",
		player.facing,
		player.run_direction,
		player.translation.x,
		player.translation.y,
		player.velocity.x,
		player.velocity.y,
		player.kick_angle,
		player.state,
		player.flags,
		player.timed_flags,
		player.recall_cast_point,
		world.camera.target,
		extents,
	)
	rl.DrawText(
		strings.clone_to_cstring(player_string, allocator = context.temp_allocator),
		20,
		100,
		16,
		rl.YELLOW,
	)
	ball_string := fmt.tprintf(
		"Ball:\n\tTranslation: [%.1f,%.1f]\n\tVelocity: [%.1f,%.1f]\n\tSpin: %.2f\n\tState: %v\n\tFlags: %v\n\tTimed Flags: %v",
		ball.translation.x,
		ball.translation.y,
		ball.velocity.x,
		ball.velocity.y,
		ball.spin,
		ball.state,
		ball.flags,
		ball.timed_flags,
	)
	rl.DrawText(
		strings.clone_to_cstring(ball_string, allocator = context.temp_allocator),
		800,
		100,
		16,
		rl.YELLOW,
	)
}

debug_cannons :: proc() {
	for entity in assets.room_entities[world.current_room] {
		if entity.tag == .Cannon_Glyph {
			data := entity.data.(tags.Cannon_Data)
			cannon_string := fmt.tprintf(
				"Cannon\n\tholding_ball: %v\n\tstate: %v\n\tshoot_timer: %.2f",
				data.holding_ball,
				data.state,
				data.shoot_timer,
			)
			ratio := f32(WINDOW_WIDTH) / SCREEN_WIDTH
			text_position := rl.GetWorldToScreen2D(entity.pos, world.camera) * ratio + {85, 0}
			rl.DrawTextEx(
				assets.font,
				strings.clone_to_cstring(cannon_string, allocator = context.temp_allocator),
				text_position,
				8,
				0,
				rl.YELLOW,
			)

		}
	}
}
