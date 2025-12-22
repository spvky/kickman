package main

import l "core:math/linalg"
import rl "vendor:raylib"

input_buffer: Input_Buffer

Input_Buffer :: struct {
	actions: [Input_Action]Buffered_Input,
}

Buffered_Input :: union {
	f32,
}

Input_Action :: enum {
	Jump,
	Dash,
	Kick,
}

update_buffer :: proc() {
	frametime := rl.GetFrameTime()

	for &buffered in input_buffer.actions {
		switch &v in buffered {
		case f32:
			v -= frametime
			if v <= 0 {
				buffered = nil
			}
		}
	}
}

buffer_action :: proc(action: Input_Action) {
	switch &v in input_buffer.actions[action] {
	case f32:
		v = 0.15
	case:
		input_buffer.actions[action] = 0.15
	}
}

consume_action :: proc(action: Input_Action) {
	input_buffer.actions[action] = nil
}

is_action_buffered :: proc(action: Input_Action) -> bool {
	_, action_pressed := input_buffer.actions[action].(f32)
	return action_pressed
}

poll_input :: proc() {
	direction: Vec2
	facing := world.player.facing
	if rl.IsKeyDown(.A) {
		direction.x -= 1
		facing = -1
	}
	if rl.IsKeyDown(.D) {
		direction.x += 1
		facing = 1
	}
	if rl.IsKeyDown(.W) {
		direction.y -= 1
	}
	if rl.IsKeyDown(.S) {
		direction.y += 1
	}

	world.player.movement_delta = direction.x
	world.player.input_direction =
		direction != Vec2{0, 0} ? l.normalize(direction) : Vec2{world.player.facing, 0}
	world.player.facing = facing
	world.player.foot_position =
		world.player.translation +
		Vec2{world.player.facing * (world.player.radius * 0.75), world.player.radius}
	update_buffer()
	if rl.IsKeyPressed(.SPACE) do buffer_action(.Jump)
	if rl.IsKeyPressed(.K) do buffer_action(.Kick)
}
