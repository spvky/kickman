package main

import "core:math"
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
	bg_color: rl.Color
	switch world.current_room.region_tag {
	case .tutorial:
		bg_color = {33, 38, 63, 255}
	case .field:
		bg_color = rl.PINK
	}
	rl.ClearBackground(bg_color)
	draw_paralax_layers()
	draw_room_entities()
	draw_current_room()
	draw_ball()
	draw_player()
	draw_dust()
	draw_tooltips()
	// draw_text()
	if ODIN_DEBUG {
		draw_level_collision()
		draw_transitions()
	}
	rl.EndMode2D()
	if world.render_mode == .Scaled {
		rl.EndTextureMode()
	}
}

render_ui_to_texture :: proc() {
	rl.BeginTextureMode(assets.ui_texture)
	rl.ClearBackground({0, 0, 0, 0})
	draw_region_banner()
	rl.EndTextureMode()
}

render_to_screen :: proc() {
	render_scene_to_texture()
	render_ui_to_texture()
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
		// Gameplay Texture
		rl.DrawTexturePro(
			assets.gameplay_texture.texture,
			source,
			dest,
			origin,
			rotation,
			rl.WHITE,
		)
		// UI Texture
		rl.DrawTexturePro(assets.ui_texture.texture, source, dest, origin, rotation, rl.WHITE)
	}
	rl.DrawFPS(0, 0)
	if ODIN_DEBUG {
		player_debug()
	}
	rl.EndDrawing()
}

draw_current_room :: proc() {
	rl.DrawTexture(assets.room_textures[world.current_room], 0, 0, rl.WHITE)
	rl.DrawTexture(assets.room_deco_textures[world.current_room], 0, 0, rl.WHITE)
}

draw_player :: proc() {
	player := world.player
	ball := world.ball
	delta := rl.GetFrameTime()
	dest := rl.Rectangle {
		x      = player.translation.x - (player.animation.sprite_width) / 2,
		y      = player.translation.y - (player.animation.sprite_height) * 0.68,
		width  = player.animation.sprite_width,
		height = player.animation.sprite_height,
	}
	player_frame := get_frame(player.animation, player.facing)
	rl.DrawTexturePro(assets.player_texture, player_frame, dest, VEC_0, 0, rl.WHITE)


	if ODIN_DEBUG {
		player_bounce_box := AABB {
			player.translation - {player.radius * 1.5, 0},
			player.translation + ({player.radius * 1.5, player.radius * 2}),
		}
		box_extents := player_bounce_box.max - player_bounce_box.min
		rl.DrawRectangleV(player_bounce_box.min, box_extents, {255, 255, 255, 100})
	}
}

draw_ball :: proc() {
	player := world.player
	ball := world.ball
	switch player.badge_type {
	case .Striker:
		ball_color := rl.WHITE
		if ball_is(.Revved) {
			t := math.sin(ball.juice_values[.Rev_Flash] * 20)
			white: [4]f32 = {255, 255, 255, 255}
			red: [4]f32 = {255, 0, 0, 255}
			float_color := math.lerp(white, red, t)

			ball_color = rl.Color {
				u8(float_color.r),
				u8(float_color.g),
				u8(float_color.b),
				u8(float_color.a),
			}
		} else if ball_is(.Recalling) {
			ball_color = {165, 134, 236, 255}
			sigil_color: rl.Color = {ball_color.r, ball_color.g, ball_color.b, 200}
			rl.DrawPolyLinesEx(
				ball.translation,
				5,
				6,
				-ball.juice_values[.Sigil_Rotation],
				2,
				sigil_color,
			)
			rl.DrawPolyLinesEx(
				ball.translation,
				3,
				6,
				ball.juice_values[.Sigil_Rotation],
				2,
				sigil_color,
			)
		}
		rl.DrawCircleV(ball.translation, ball.radius, ball_color)
	case .Sisyphus:
		rl.DrawCircleV(ball.translation, ball.radius * 4, rl.WHITE)
	case .Ghost:
	}
}

draw_dust :: proc() {
	render_particle_emitter(&world.particles.dust_particles)
}

draw_level_collision :: proc() {
	for collider in assets.room_collision[world.current_room] {
		color := .Oneway in collider.flags ? rl.YELLOW : rl.RED
		extents := collider.max - collider.min
		rl.DrawRectangleV(collider.min, extents, color)
		a := collider.min
		b := Vec2{collider.max.x, collider.min.y}
		c := collider.max
		d := Vec2{collider.min.x, collider.max.y}
		rl.DrawLineEx(a, b, 2, {255, 255, 255, 100})
		rl.DrawLineEx(b, c, 2, {255, 255, 255, 100})
		rl.DrawLineEx(c, d, 2, {255, 255, 255, 100})
		rl.DrawLineEx(d, a, 2, {255, 255, 255, 100})
	}
}

draw_transitions :: proc() {
	for transition in assets.room_transitions[world.current_room] {
		extents := transition.max - transition.min
		rl.DrawRectangleV(transition.min, extents, rl.BLUE)
	}
}
