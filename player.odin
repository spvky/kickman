package main

import "core:log"
import "core:math"


TILE_SIZE: f32 : 8
// How far can the player jump horizontally (in pixels)
MAX_JUMP_DISTANCE: f32 : 4 * TILE_SIZE
// How long to reach jump peak (in seconds)
TIME_TO_PEAK: f32 : 0.3
// How long to reach height we jumped from (in seconds)
TIME_TO_DESCENT: f32 : 0.25
// How many pixels high can we jump
JUMP_HEIGHT: f32 : 3 * TILE_SIZE

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
	// TODO: replace input direction with Kick angles, define the kick angles for the Striker Badge
	kick_angle:      Kick_Angle,
	foot_position:   Vec2,
	movement_delta:  f32,
	facing:          f32,
	carry_pos:       f32,
	ignore_ball:     f32,
	state_flags:     bit_set[Player_State;u8],
	has_ball:        bool,
}

Kick_Angle :: enum u8 {
	Up,
	Forward,
	Down,
}

Player_State :: enum u8 {
	Grounded,
	DoubleJump,
}

Ball :: struct {
	using rigidbody: Rigidbody,
	ignore_player:   f32,
	carried:         bool,
	spin:            f32,
	state_flags:     bit_set[Ball_State;u8],
}

Ball_State :: enum u8 {
	Grounded,
}

manage_ignore_ball :: proc(delta: f32) {
	player := &world.player
	if player.ignore_ball > 0 {
		player.ignore_ball = math.clamp(player.ignore_ball - delta, 0, 5)
	}
}

player_kick :: proc() {
	player := &world.player
	ball := &world.ball
	if is_action_buffered(.Kick) {
		if player.has_ball && ball.carried {
			ball_angle: Vec2
			switch player.kick_angle {
			case .Up:
				ball_angle = Vec2{0, -1}
			case .Forward:
				ball_angle = Vec2{player.facing, -0.4}
			case .Down:
				ball_angle = Vec2{player.facing * 0.4, -0.9}
			}
			ball.translation = player.foot_position
			ball.carried = false
			player.has_ball = false
			ball.velocity = (300 * ball_angle) + player.velocity
			// Instead of the movement direction system, hone some specific angles:
			// - Heel kick up (Up)
			// - Normal Shot (Forward/Neutral)
			// - Low shot (Grounded, Down)
			// - Straight down shot (Airborne, Down)
			player.ignore_ball = 0.2
			ball.spin = player.facing
			consume_action(.Kick)
		}
	}
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

catch_ball :: proc() {
	player := &world.player
	ball := &world.ball
	ball.carried = true
	ball.velocity = Vec2{0, 0}
	player.has_ball = true
}
