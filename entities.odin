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
				y      = 88,
			}
			if on {
				source.x = 48
			} else {
				source.x = 56
			}
			rl.DrawTexturePro(assets.raw_atlas, source, dest, {0, 0}, 0, rl.WHITE)
		case .Button:
		case .Checkpoint:
			draw_checkpoint(entity)
		case .Movable_Block:
			data := entity.data.(tags.Movable_Block_Data)
			// rl.DrawRectangleV(entity.pos, data.extents, rl.BLACK)
			source := rl.Rectangle {
				x      = 0,
				y      = 72,
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
			rl.DrawTextureNPatch(assets.raw_atlas, patch_info, dest, {0, 0}, 0, rl.WHITE)
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
	origin := entity.pos + {4, 4} - VEC_Y * data.animation_value * 16

	triangle_rotation := 90 + data.animation_value * 180
	rl.DrawCircleV(origin, 4, dot_color)
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
