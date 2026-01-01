package main

import tags "tags"
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
		}
	}
}
