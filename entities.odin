package main

import "core:log"
import "core:math"
import l "core:math/linalg"
import "tags"
import rl "vendor:raylib"

draw_room_entities :: proc() {
	for entity in assets.room_entities[world.current_room] {
		switch entity.tag {
		case .Lever:
			on := entity.data.(tags.Trigger_Data).on
			dest := rl.Rectangle {
				x      = entity.pos.x,
				y      = entity.pos.y,
				width  = 8,
				height = 8,
			}
			source := rl.Rectangle {
				width  = 8,
				height = 8,
				y      = 0,
			}
			if on {
				source.x = 40
			} else {
				source.x = 48
			}
			rl.DrawTexturePro(assets.entities_atlas, source, dest, {0, 0}, 0, rl.WHITE)
		case .Eye:
			data := entity.data.(tags.Trigger_Data)
			dest := rl.Rectangle {
				x      = entity.pos.x,
				y      = entity.pos.y,
				width  = 16,
				height = 16,
			}
			source := rl.Rectangle {
				width  = 16,
				height = 16,
				x      = 40,
				y      = 8,
			}
			pentagon_rotation := 90 + data.active_value * 180

			sigil_color: Color_F = math.lerp(COLOR_SIGIL_WHITE, COLOR_CAPTURED, data.active_value)

			rl.DrawTexturePro(
				assets.entities_atlas,
				source,
				dest,
				{0, 0},
				0,
				to_rl_color(sigil_color),
			)
			rl.DrawPolyLines(
				entity.pos + {8, 8},
				5,
				12,
				pentagon_rotation,
				to_rl_color(sigil_color),
			)
		case .Cannon_Glyph:
			data := entity.data.(tags.Cannon_Data)
			dest := rl.Rectangle {
				x      = entity.pos.x,
				y      = entity.pos.y,
				width  = 16,
				height = 16,
			}
			source := rl.Rectangle {
				width  = 16,
				height = 16,
				x      = 40,
				y      = 8,
			}
			sigil_color: Color_F = math.lerp(COLOR_CANNON, COLOR_CANNON, data.active_value)
			shape_origin := entity.pos + {8, 8}
			rl.DrawTexturePro(
				assets.entities_atlas,
				source,
				dest,
				{0, 0},
				0,
				to_rl_color(sigil_color),
			)
			rl.DrawPolyLines(shape_origin, 3, 12, data.rotation, to_rl_color(sigil_color))

			tail_radius: f32 = 12
			angle_radians := math.to_radians(data.rotation + 180)
			tail_start :=
				shape_origin +
				{
						(data.shoot_timer * 16) * math.cos(angle_radians),
						(data.shoot_timer * 16) * math.sin(angle_radians),
					}
			tail_end :=
				shape_origin +
				{
						((data.shoot_timer * 16) + tail_radius) * math.cos(angle_radians),
						((data.shoot_timer * 16) + tail_radius) * math.sin(angle_radians),
					}
			rl.DrawLineEx(tail_start, tail_end, 1, to_rl_color(sigil_color))
			rl.DrawCircleLinesV(shape_origin, data.shoot_timer * 16, to_rl_color(sigil_color))

		case .Checkpoint:
			draw_checkpoint(entity)
		case .Movable_Block:
			data := entity.data.(tags.Movable_Block_Data)
			source := rl.Rectangle {
				x      = 0,
				y      = 0,
				width  = 24,
				height = 24,
			}
			dest := rl.Rectangle {
				x      = entity.pos.x,
				y      = entity.pos.y,
				width  = data.extents.x,
				height = data.extents.y,
			}
			patch_info := rl.NPatchInfo {
				source = source,
				top    = 8,
				left   = 8,
				right  = 8,
				bottom = 8,
				layout = .NINE_PATCH,
			}
			rl.DrawTextureNPatch(assets.entities_atlas, patch_info, dest, {0, 0}, 0, rl.WHITE)
		}
	}
}

draw_checkpoint :: proc(entity: tags.Entity) {
	data := entity.data.(tags.Checkpoint_Data)

	raw_dot_color := math.lerp([4]f32{1, 1, 1, 0.8}, [4]f32{0, 1, 0, 1}, data.animation_value)
	dot_color: rl.Color = {
		u8(raw_dot_color.r * 255),
		u8(raw_dot_color.b * 255),
		u8(raw_dot_color.g * 255),
		u8(raw_dot_color.a * 255),
	}

	raw_sigil_color := math.lerp([4]f32{1, 1, 1, 0}, [4]f32{0, 1, 0, 1}, data.animation_value)
	sigil_color: rl.Color = {
		u8(raw_sigil_color.r * 255),
		u8(raw_sigil_color.b * 255),
		u8(raw_sigil_color.g * 255),
		u8(raw_sigil_color.a * 255),
	}
	origin := entity.pos + {4, 4} - (VEC_Y * 8) - (VEC_Y * data.animation_value) * 12

	holder_source := rl.Rectangle {
		x      = 32,
		y      = 16,
		width  = 8,
		height = 8,
	}

	holder_dest := rl.Rectangle {
		x      = entity.pos.x,
		y      = entity.pos.y,
		width  = 8,
		height = 8,
	}


	ball_source := rl.Rectangle {
		x      = 32,
		y      = 8,
		width  = 8,
		height = 8,
	}

	ball_dest := rl.Rectangle {
		x      = origin.x - 4,
		y      = origin.y - 4,
		width  = 8,
		height = 8,
	}

	triangle_rotation := 90 + data.animation_value * 180
	rl.DrawTexturePro(assets.entities_atlas, holder_source, holder_dest, {0, 0}, 0, rl.WHITE)
	rl.DrawTexturePro(assets.entities_atlas, ball_source, ball_dest, {0, 0}, 0, dot_color)
	// rl.DrawCircleV(origin, 4, dot_color)
	rl.DrawPolyLines(origin, 3, 16, triangle_rotation, sigil_color)
	rl.DrawPolyLines(origin, 6, 16, triangle_rotation, sigil_color)
}


update_entities :: proc(delta: f32) {
	for &entity in assets.room_entities[world.current_room] {
		#partial switch entity.tag {
		case .Checkpoint:
			data := &entity.data.(tags.Checkpoint_Data)
			spawn := world.spawn_point
			check_spawn := Spawn_Point {
				room_tag = world.current_room,
				position = entity.pos,
			}
			if spawn == check_spawn {
				data.active = true
				if data.animation_value > 0.97 {
					data.animation_value = 1
				} else {
					data.animation_value = math.lerp(data.animation_value, 1, delta * 5)
				}
			} else {
				data.active = false
				if data.animation_value < 0.06 {
					data.animation_value = 0
				} else {
					data.animation_value = math.lerp(data.animation_value, 0, delta * 2.5)
				}
			}

		case .Eye:
			data := &entity.data.(tags.Trigger_Data)
			if data.on {
				if data.active_value < 0.98 {
					data.active_value += delta * 2.5
				} else {
					data.active_value = 1
				}
			} else {
				if data.active_value > 0.02 {
					data.active_value -= delta * 2.5
				} else {
					data.active_value = 0
				}
			}
		case .Cannon_Glyph:
			data := &entity.data.(tags.Cannon_Data)
			if data.holding_ball {
				if data.active_value < 0.98 {
					data.active_value += delta * 2.5
				} else {
					data.active_value = 1
				}

				if !data.holding_ball_previous && data.holding_ball {
					data.state = .Charging
				}

				switch data.state {
				case .Dormant:
					if data.holding_ball {
						data.state = .Charging
					}
				case .Charging:
					data.shoot_timer += delta * 10
					if data.shoot_timer >= 1 {
						data.state = .Firing
					}
				case .Firing:
					data.shoot_timer -= delta * 20
					if data.shoot_timer <= 0 {
						data.state = .Dormant
						angle_radians := math.to_radians(data.rotation)
						world.ball.velocity = {
							500 * math.cos(angle_radians),
							500 * math.sin(angle_radians),
						}
						ball_t_add(.Ignore_Glyphs, 0.05)
						ball_t_add(.No_Gravity, 0.25)
						world.ball.state = .Free
						data.shoot_timer = 0
						data.active_value = 0
					}
				}
			} else {
				if data.active_value > 0.02 {
					data.active_value -= delta * 2.5
				} else {
					data.active_value = 0
				}
			}
			data.holding_ball_previous = data.holding_ball
		case .Movable_Block:
			data := &entity.data.(tags.Movable_Block_Data)
			trigger_data := assets.room_entities[data.trigger_room][data.trigger_index].data.(tags.Trigger_Data)
			signal := trigger_data.on

			// Lerp to location based on signal value
			previous_pos := entity.pos
			target_pos := signal ? data.positions[1] : data.positions[0]
			if l.distance(entity.pos, target_pos) < 1 {
				entity.pos = target_pos
				data.velocity = VEC_0
			} else {
				entity.pos = math.lerp(entity.pos, target_pos, data.speed * delta)
				data.velocity = (entity.pos - previous_pos) / delta
			}
		}
	}
}

update_transitions :: proc() {
	for &transition in assets.room_transitions[world.current_room] {
		if transition.touching_player != transition.prev_touching_player {
			if transition.prev_touching_player && !transition.touching_player {
				transition.active = true
			} else if transition.touching_player && !transition.prev_touching_player {
				transition.active = false
			}
		}

		if !transition.touching_player && !transition.prev_touching_player {
			transition.active = true
		}
	}
}
