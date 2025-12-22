package main

import "core:log"
import "core:math"


TILE_SIZE: f32 : 16
// How far can the player jump horizontally (in pixels)
MAX_JUMP_DISTANCE: f32 : 3 * TILE_SIZE
// How long to reach jump peak (in seconds)
TIME_TO_PEAK: f32 : 0.3
// How long to reach height we jumped from (in seconds)
TIME_TO_DESCENT: f32 : 0.25
// How many pixels high can we jump
JUMP_HEIGHT: f32 : 2 * TILE_SIZE

max_speed := calculate_max_speed()
jump_speed := calulate_jump_speed()
rising_gravity := calculate_rising_gravity()
falling_gravity := calculate_falling_gravity()

calulate_jump_speed :: proc "c" () -> f32 {
	return (-2 * JUMP_HEIGHT) / TIME_TO_PEAK
}

calculate_rising_gravity :: proc "c" () -> f32 {
	return (2 * JUMP_HEIGHT) / math.pow(TIME_TO_PEAK, 2)
}

calculate_falling_gravity :: proc "c" () -> f32 {
	return (2 * JUMP_HEIGHT) / math.pow(TIME_TO_DESCENT, 2)
}

calculate_max_speed :: proc "c" () -> f32 {
	return MAX_JUMP_DISTANCE / (TIME_TO_PEAK + TIME_TO_DESCENT)
}

Player :: struct {
	using rigidbody: Rigidbody,
	move_delta:      f32,
	facing:          f32,
	carry_pos:       f32,
	state_flags:     bit_set[Player_State],
	has_ball:        bool,
}

Player_State :: enum u8 {
	Grounded,
	DoubleJump,
}

Ball :: struct {
	using rigidbody: Rigidbody,
	carried:         bool,
}

Ball_State :: enum u8 {
	Grounded,
}


player_jump :: proc() {
	player := &world.player
	if is_action_buffered(.Jump) {
		if .Grounded in player.state_flags {
			player.velocity.y = jump_speed
			consume_action(.Jump)
			return
		}
	}
}
