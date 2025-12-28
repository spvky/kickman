package main

import rl "vendor:raylib"

Render_Mode :: enum {
	Zoomed,
	Scaled,
}

render :: proc() {
	render_scene_to_texture()
	render_to_screen()
}

render_scene_to_texture :: proc() {
	if world.render_mode == .Scaled {
		rl.BeginTextureMode(assets.gameplay_texture)
		world.camera.zoom = 1
	} else {
		world.camera.zoom = 4.8
	}
	rl.BeginMode2D(world.camera)
	rl.ClearBackground({255, 229, 180, 255})
	draw_current_room()
	draw_player_and_ball()
	if ODIN_DEBUG {
		draw_level_collision()
	}
	rl.EndMode2D()
	if world.render_mode == .Scaled {
		rl.EndTextureMode()
	}
}

render_to_screen :: proc() {

	render_scene_to_texture()
	if world.render_mode == .Scaled {
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
		rl.DrawTexturePro(
			assets.gameplay_texture.texture,
			source,
			dest,
			origin,
			rotation,
			rl.WHITE,
		)
	}
	player_debug()
	rl.EndDrawing()
}

draw_current_room :: proc() {
	rl.DrawTexture(assets.room_textures[world.current_room], 0, 0, rl.WHITE)
}

draw_player_and_ball :: proc() {
	player := world.player
	ball := world.ball
	player_bounce_box := AABB {
		player.translation - {player.radius * 1.5, 0},
		player.translation + ({player.radius * 1.5, player.radius * 2}),
	}
	box_extents := player_bounce_box.max - player_bounce_box.min
	rl.DrawCircleV(player.translation + {0, player.radius / 2}, player.radius, rl.BLUE)
	rl.DrawCircleV(player.translation - {0, player.radius / 2}, player.radius, rl.BLUE)
	rl.DrawRectangleV(player_bounce_box.min, box_extents, {255, 255, 255, 100})
	if ball_has(.Carried) {
		rl.DrawCircleV(player.foot_position, ball.radius, rl.WHITE)
	} else {
		rl.DrawCircleV(ball.translation, ball.radius, rl.WHITE)
	}
}

draw_level_collision :: proc() {
	for collider in assets.room_collision[world.current_room].room_collision {
		extents := collider.max - collider.min
		rl.DrawRectangleV(collider.min, extents, rl.RED)
	}
}
