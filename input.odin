package main

import "core:log"
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
	Reset,
}

check_pads_down :: proc(count: i32, button: rl.GamepadButton) -> bool {
	for i in 0 ..< count {
		if rl.IsGamepadButtonDown(i, button) {
			return true
		}
	}
	return false
}
check_pads_pressed :: proc(count: i32, button: rl.GamepadButton) -> bool {
	for i in 0 ..< count {
		if rl.IsGamepadButtonPressed(i, button) {
			return true
		}
	}
	return false
}
check_pads_released :: proc(count: i32, button: rl.GamepadButton) -> bool {
	for i in 0 ..< count {
		if rl.IsGamepadButtonReleased(i, button) {
			return true
		}
	}
	return false
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
	if rl.IsKeyDown(.A) || check_pads_down(3, .LEFT_FACE_LEFT) {
		direction.x -= 1
	}
	if rl.IsKeyDown(.D) || check_pads_down(3, .LEFT_FACE_RIGHT) {
		direction.x += 1
	}
	if rl.IsKeyDown(.W) || check_pads_down(3, .LEFT_FACE_UP) {
		direction.y -= 1
	}
	if rl.IsKeyDown(.S) || check_pads_down(3, .LEFT_FACE_DOWN) {
		direction.y += 1
	}

	kick_angle: Kick_Angle

	if direction.y < 0 {
		kick_angle = .Up
	} else {
		kick_angle = .Forward
	}


	player.movement_delta = direction.x
	player.kick_angle = kick_angle
	// player.facing = facing
	update_buffer()
	// Buffer pressed inputs
	if rl.IsKeyPressed(.SPACE) || check_pads_pressed(3, .RIGHT_FACE_DOWN) {
		if rl.IsKeyDown(.S) || check_pads_down(3, .LEFT_FACE_DOWN) {
			buffer_action(.Slide)
		} else {
			buffer_action(.Jump)
		}
	}
	if rl.IsKeyPressed(.K) || check_pads_pressed(3, .RIGHT_FACE_LEFT) do buffer_action(.Kick)
	if rl.IsKeyPressed(.J) || check_pads_pressed(3, .RIGHT_FACE_UP) do buffer_action(.Badge)
	if rl.IsKeyPressed(.S) || check_pads_pressed(3, .LEFT_FACE_DOWN) do buffer_action(.Crouch)
	if rl.IsKeyPressed(.H) || check_pads_pressed(3, .RIGHT_TRIGGER_1) do buffer_action(.Dash)
	if rl.IsKeyPressed(.R) || check_pads_pressed(3, .RIGHT_TRIGGER_2) do buffer_action(.Reset)

	if rl.IsKeyReleased(.SPACE) || check_pads_released(3, .RIGHT_FACE_DOWN) do release_action(.Jump)
	if rl.IsKeyReleased(.K) || check_pads_released(3, .RIGHT_FACE_LEFT) do release_action(.Kick)
	if rl.IsKeyReleased(.J) || check_pads_released(3, .RIGHT_FACE_UP) do release_action(.Badge)
	if rl.IsKeyReleased(.S) || check_pads_released(3, .LEFT_FACE_DOWN) do release_action(.Crouch)
	if rl.IsKeyReleased(.H) || check_pads_released(3, .RIGHT_TRIGGER_1) do release_action(.Dash)
	if rl.IsKeyReleased(.R) || check_pads_released(3, .RIGHT_TRIGGER_2) do buffer_action(.Reset)
}
