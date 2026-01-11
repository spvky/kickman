package main

import "core:math"
import "core:strings"
import "tags"
import rl "vendor:raylib"

update_tooltips :: proc(delta: f32) {
	for &tt in assets.room_tooltips[world.current_room] {
		if tt.touching_player && tt.current_opacity != 1 {
			tt.current_opacity = math.clamp(tt.current_opacity + delta * 2, 0, 1)
		} else if !tt.touching_player && tt.current_opacity != 0 {
			tt.current_opacity = math.clamp(tt.current_opacity - delta, 0, 1)
		}
	}
}

draw_tooltips :: proc() {
	for tt in assets.room_tooltips[world.current_room] {
		if tt.current_opacity != 0 {
			int_opacity := u8(tt.current_opacity * 255)
			color := rl.Color{255, 255, 255, int_opacity}
			rl.DrawTextEx(
				assets.font,
				strings.clone_to_cstring(tt.message, allocator = context.temp_allocator),
				tt.display_point,
				8,
				0,
				color,
			)
		}
	}
}
