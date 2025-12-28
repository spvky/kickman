package main

import "core:log"
import "core:math"
import "core:time"


TILE_SIZE: f32 : 8
// How far can the player jump horizontally (in pixels)
MAX_JUMP_DISTANCE: f32 : 7 * TILE_SIZE
// How long to reach jump peak (in seconds)
TIME_TO_PEAK: f32 : 0.3
// How long to reach height we jumped from (in seconds)
TIME_TO_DESCENT: f32 : 0.25
// How many pixels high can we jump
JUMP_HEIGHT: f32 : 3.25 * TILE_SIZE

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
	using rigidbody:   Rigidbody,
	// TODO: replace input direction with Kick angles, define the kick angles for the Striker Badge
	kick_angle:        Kick_Angle,
	foot_position:     Vec2,
	movement_delta:    f32,
	facing:            f32,
	carry_pos:         f32,
	state_flags:       bit_set[Player_State;u8],
	timed_state_flags: bit_set[Player_Timed_State;u8],
	flag_timers:       [Player_Timed_State]f32,
	badge_type:        Player_Badge,
	has_ball:          bool,
}

Player_Badge :: enum u8 {
	None,
	Striker,
	Sisyphus,
	Ghost,
}

Kick_Angle :: enum u8 {
	Up,
	Forward,
	Down,
}

Player_State :: enum u8 {
	Grounded,
	Double_Jump,
}

Player_Timed_State :: enum u8 {
	Coyote,
	Ignore_Ball,
	No_Badge,
}

Player_Master_State :: enum u16 {
	Grounded,
	Double_Jump,
	Coyote,
	Ignore_Ball,
	No_Badge,
}

Ball :: struct {
	using rigidbody:   Rigidbody,
	ignore_player:     f32,
	spin:              f32,
	state_flags:       bit_set[Ball_State;u8],
	timed_state_flags: bit_set[Ball_Timed_State;u8],
	flag_timers:       [Ball_Timed_State]f32,
}

Ball_State :: enum u8 {
	Carried,
	Grounded,
	Recalling,
}

Ball_Timed_State :: enum u8 {
	No_Gravity,
}

Ball_Master_State :: enum u16 {
	Carried,
	Grounded,
	Recalling,
	No_Gravity,
}

// Check if the player has the passed state flag
@(require_results)
player_has :: proc(flag: Player_Master_State) -> (contains: bool) {
	switch flag {
	case .Grounded:
		contains = .Grounded in world.player.state_flags
	case .Double_Jump:
		contains = .Double_Jump in world.player.state_flags
	case .Coyote:
		contains = .Coyote in world.player.timed_state_flags
	case .Ignore_Ball:
		contains = .Ignore_Ball in world.player.timed_state_flags
	case .No_Badge:
		contains = .No_Badge in world.player.timed_state_flags
	}
	return contains
}

// Check if the ball has the passed state flag
@(require_results)
ball_has :: proc(flag: Ball_Master_State) -> (contains: bool) {
	switch flag {
	case .Carried:
		contains = .Carried in world.ball.state_flags
	case .Grounded:
		contains = .Grounded in world.ball.state_flags
	case .Recalling:
		contains = .Recalling in world.ball.state_flags
	case .No_Gravity:
		contains = .No_Gravity in world.ball.timed_state_flags
	}
	return contains
}


manage_player_ball_timed_state_flags :: proc(delta: f32) {
	player := &world.player
	ball := &world.ball
	for v in Player_Timed_State {
		timer := &player.flag_timers[v]
		timer^ = math.clamp(timer^ - delta, 0, 10)
		if timer^ > 0.0 {
			player.timed_state_flags += {v}
		} else {
			player.timed_state_flags -= {v}
		}
	}
	for v in Ball_Timed_State {
		timer := &ball.flag_timers[v]
		timer^ = math.clamp(timer^ - delta, 0, 10)
		if timer^ > 0.0 {
			ball.timed_state_flags += {v}
		} else {
			ball.timed_state_flags -= {v}
		}
	}
}

player_kick :: proc() {
	player := &world.player
	ball := &world.ball
	if is_action_buffered(.Kick) {
		if player.has_ball && ball_has(.Carried) {
			ball_angle: Vec2
			switch player.kick_angle {
			case .Up:
				ball_angle = Vec2{0, -1}
			case .Forward:
				ball_angle = Vec2{player.facing, 0} //-0.4}
			case .Down:
				ball_angle = Vec2{player.facing * 0.4, -0.9}
			}
			ball.translation = player.foot_position

			ball.state_flags -= {.Carried}
			player.has_ball = false
			ball.velocity = (200 * ball_angle) + player.velocity
			// Instead of the movement direction system, hone some specific angles:
			// - Heel kick up (Up)
			// - Normal Shot (Forward/Neutral)
			// - Low shot (Grounded, Down)
			// - Straight down shot (Airborne, Down)
			player.flag_timers[.Ignore_Ball] = 0.2
			ball.spin = player.facing
			consume_action(.Kick)
		}
	}
}

player_action :: proc() {
	player := &world.player
	ball := &world.ball
	if is_action_buffered(.Badge) && .No_Badge not_in player.timed_state_flags {
		switch player.badge_type {
		case .None:
		case .Striker:
			player.flag_timers[.No_Badge] = 1
			ball.state_flags += {.Recalling}
			consume_action(.Badge)
		case .Sisyphus:
		case .Ghost:
		}
	}
}


player_jump :: proc() {
	player := &world.player
	if is_action_buffered(.Jump) {
		if .Grounded in player.state_flags || .Coyote in player.timed_state_flags {
			player.velocity.y = jump_speed
			player.timed_state_flags -= {.Coyote}
			consume_action(.Jump)
			return
		}
	}
}

catch_ball :: proc() {
	player := &world.player
	ball := &world.ball
	ball.state_flags += {.Carried}
	ball.velocity = Vec2{0, 0}
	player.has_ball = true
}
