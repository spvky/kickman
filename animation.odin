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
	meta:       Animation_Meta,
}

Animation_Meta :: union #no_nil {
	Animation_Looped,
	Animation_Oneshot,
}

Animation_Looped :: struct {}

Animation_Oneshot :: struct {
	next: Animation_Action,
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
	Crouch,
	Sleep,
	Carry_Heavy_Run,
	Carry_Heavy_Idle,
}

player_animations :: proc() -> [Animation_Action]Animation {
	return {
		.Idle = {start = 0, end = 8},
		.Flourish = {start = 9, end = 15, meta = Animation_Oneshot{next = .Idle}},
		.Balance = {start = 16, end = 23},
		.Run = {start = 24, end = 31},
		.Cling = {start = 32, end = 39},
		.Wall_Slide = {start = 40, end = 47},
		.Rise = {start = 48, end = 53},
		.Fall = {start = 54, end = 60},
		.Crouch = {start = 61, end = 61},
		.Sleep = {start = 62, end = 63},
		.Carry_Heavy_Run = {start = 64, end = 71},
		.Carry_Heavy_Idle = {start = 72, end = 79},
	}
}

set_frame_length :: proc(anim: ^Animation_Player, frame_length: f32) {
	anim.frame_length = frame_length
}

update_animation_player :: proc(anim: ^Animation_Player, delta: f32) {
	if anim.state != anim.prev_state {
		anim.frame_time = 0
		anim.frame = anim.animations[anim.state].start
	} else {
		anim.frame_time += delta
		if anim.frame_time > anim.frame_length {
			anim.frame_time = 0
			new_index := anim.frame + 1
			if new_index > anim.animations[anim.state].end {
				switch v in anim.animations[anim.state].meta {
				case Animation_Looped:
					new_index = anim.animations[anim.state].start
				case Animation_Oneshot:
					new_index = anim.animations[v.next].start
					anim.state = v.next
				}
			}
			anim.frame = new_index
		}
	}
	anim.prev_state = anim.state
}
