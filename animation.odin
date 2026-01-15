package main

import "core:log"
import rl "vendor:raylib"

Animation_Player :: struct {
	frame:                       u16,
	frame_time:                  f32,
	frame_length:                f32,
	sheet_width, sheet_height:   f32,
	sprite_height, sprite_width: f32,
	animations:                  [Animation_Action]Animation,
	state:                       Animation_Action,
	prev_state:                  Animation_Action,
}

get_frame :: proc(anim: Animation_Player, facing: f32) -> (frame: rl.Rectangle) {
	x, y: f32
	cells_x := anim.sheet_width / anim.sprite_width
	x = f32(anim.frame % u16(cells_x)) * anim.sprite_width
	y = f32(anim.frame / u16(cells_x)) * anim.sprite_height

	frame = rl.Rectangle {
		x      = x,
		y      = y,
		width  = anim.sprite_width * facing,
		height = anim.sprite_height,
	}
	return
}

Animation :: struct {
	start, end: u16,
}

Animation_Action :: enum u8 {
	Idle,
	Flourish,
	Balance,
	Run,
	Cling,
	Wall_Slide,
	Rise,
	Fall,
}

player_animations :: proc() -> [Animation_Action]Animation {
	return {
		.Idle = {0, 8},
		.Flourish = {9, 15},
		.Balance = {16, 23},
		.Run = {24, 31},
		.Cling = {32, 39},
		.Wall_Slide = {40, 47},
		.Rise = {48, 53},
		.Fall = {54, 60},
	}
}

f_time: f32

update_animation_player :: proc(anim: ^Animation_Player, delta: f32) {
	if anim.state != anim.prev_state {
		anim.frame_time = 0
		anim.frame = anim.animations[anim.state].start
	} else {
		anim.frame_time += delta
		if anim.frame_time > anim.frame_length {
			log.debug("Flipping")
			anim.frame_time = 0
			new_index := anim.frame + 1
			if new_index > anim.animations[anim.state].end {
				new_index = anim.animations[anim.state].start
			}
			anim.frame = new_index
		}
	}
	anim.prev_state = anim.state
}
