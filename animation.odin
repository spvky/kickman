package main

import rl "vendor:raylib"

Animation_Player :: struct {
	index:                       u16,
	frame_time:                  f32,
	frame_length:                f32,
	sheet_width, sheet_height:   f32,
	sprite_height, sprite_width: f32,
}

get_frame :: proc(anim: Animation_Player) -> (frame: rl.Rectangle) {
	x, y: f32
	cells_x := anim.sheet_width / anim.sprite_width
	x = f32(anim.index % u16(cells_x)) * anim.sprite_width
	y = f32(anim.index / u16(cells_x)) * anim.sprite_height

	frame = rl.Rectangle {
		x      = x,
		y      = y,
		width  = anim.sprite_width,
		height = anim.sprite_height,
	}
	return
}

Animation :: struct {
	start, end: u16,
}

// TODO: Define player animations from sprite sheet
Player_Animations :: struct {}
