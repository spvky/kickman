package main

import l "core:math/linalg"
import rl "vendor:raylib"

input_buffer: Input_Buffer

Input_Buffer :: struct {
	buffered: [Input_Action]Buffered_Input,
	held:     bit_set[Input_Action;u8],
}

Buffered_Input :: union {
	f32,
}

Input_Action :: enum {
	Jump,
	Dash,
	Kick,
	Badge,
	Slide,
	Crouch,
}

update_buffer :: proc() {
	frametime := rl.GetFrameTime()

	for &buffered in input_buffer.buffered {
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
	switch &v in input_buffer.buffered[action] {
	case f32:
		v = 0.15
	case:
		input_buffer.buffered[action] = 0.15
	}
	input_buffer.held += {action}
}

release_action :: proc(action: Input_Action) {
	input_buffer.held -= {action}
}

consume_action :: proc(action: Input_Action) {
	input_buffer.buffered[action] = nil
}

is_action_buffered :: proc(action: Input_Action) -> bool {
	_, action_pressed := input_buffer.buffered[action].(f32)
	return action_pressed
}

is_action_held :: proc(action: Input_Action) -> bool {
	return action in input_buffer.held
}

poll_input :: proc() {
	player := &world.player
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

	kick_angle: Kick_Angle

	if direction.y == 0 {
		kick_angle = .Forward
	} else if direction.y < 0 {
		kick_angle = .Up
	} else {
		kick_angle = .Down
	}


	player.movement_delta = direction.x
	player.kick_angle = kick_angle
	player.facing = facing
	update_buffer()
	// Buffer pressed inputs
	if rl.IsKeyPressed(.SPACE) {
		if rl.IsKeyDown(.S) {
			buffer_action(.Slide)
		} else {
			buffer_action(.Jump)
		}
	}
	if rl.IsKeyPressed(.K) do buffer_action(.Kick)
	if rl.IsKeyPressed(.J) do buffer_action(.Badge)
	if rl.IsKeyPressed(.S) do buffer_action(.Crouch)

	if rl.IsKeyReleased(.SPACE) do release_action(.Jump)
	if rl.IsKeyReleased(.K) do release_action(.Kick)
	if rl.IsKeyReleased(.J) do release_action(.Badge)
	if rl.IsKeyReleased(.S) do release_action(.Crouch)

}
