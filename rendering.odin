package main

import rl "vendor:raylib"

render :: proc() {
	render_scene_to_texture()
	render_to_screen()
}

render_scene_to_texture :: proc() {
	rl.BeginTextureMode(assets.gameplay_texture)
	rl.ClearBackground({255, 229, 180, 255})
	// draw_level_collision()
	draw_current_room()
	draw_player_and_ball()
	draw_level_collision()
	rl.EndTextureMode()
}

render_to_screen :: proc() {
	WINDOW_HEIGHT = rl.GetScreenWidth()
	WINDOW_HEIGHT = rl.GetScreenHeight()
	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)
	source := rl.Rectangle {
		x      = 0,
		y      = f32(WINDOW_HEIGHT - SCREEN_HEIGHT),
		width  = f32(SCREEN_WIDTH),
		height = -f32(SCREEN_HEIGHT),
	}
	dest := rl.Rectangle {
		x      = 0,
		y      = 0,
		width  = f32(WINDOW_WIDTH),
		height = f32(WINDOW_HEIGHT),
	}
	origin := Vec2{0, 0}
	rotation: f32 = 0
	rl.DrawTexturePro(assets.gameplay_texture.texture, source, dest, origin, rotation, rl.WHITE)
	player_debug()
	rl.EndDrawing()
}

draw_current_room :: proc() {
	rl.DrawTexture(assets.room_textures[world.current_room], 0, 0, rl.WHITE)
}

draw_player_and_ball :: proc() {
	player := world.player
	ball := world.ball
	rl.DrawCircleV(player.translation + {0, player.radius / 2}, player.radius, rl.BLUE)
	rl.DrawCircleV(player.translation - {0, player.radius / 2}, player.radius, rl.BLUE)
	if ball.carried {
		rl.DrawCircleV(player.foot_position, ball.radius, rl.WHITE)
	} else {
		rl.DrawCircleV(ball.translation, ball.radius, rl.WHITE)
	}
	if ODIN_DEBUG {
		// Draw kick angle
		//rl.DrawCircleV(player.foot_position + (player.input_direction * 8), 4, rl.BLACK)
	}
}

draw_level_collision :: proc() {
	for collider in assets.room_collision[world.current_room].room_collision {
		extents := collider.max - collider.min
		rl.DrawRectangleV(collider.min, extents, rl.RED)
	}
}
