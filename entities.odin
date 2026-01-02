package main

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

update_entities :: proc(delta: f32) {
	for &entity in assets.room_entities[world.current_room] {
		#partial switch entity.tag {
		case .Movable_Block:
			data := &entity.data.(tags.Movable_Block_Data)
			trigger_data := assets.room_entities[world.current_room][data.trigger_index].data.(tags.Trigger_Data)
			signal := trigger_data.on

			// Lerp to location based on signal value
			previous_pos := entity.pos
			target_pos := signal ? data.positions[1] : data.positions[0]
			if l.distance(entity.pos, target_pos) < 1 {
				entity.pos = target_pos
			} else {
				entity.pos = math.lerp(entity.pos, target_pos, data.speed * delta)
			}
			data.velocity = (entity.pos - previous_pos) / delta
		}
	}
}
