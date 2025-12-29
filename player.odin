package main

import "core:log"
import "core:math"
import "core:time"


TILE_SIZE: f32 : 8
// How far can the player jump horizontally (in pixels)
JUMP_DISTANCE: f32 : 7 * TILE_SIZE
// How far can the player jump horizontally while_dashing
DASH_JUMP_DISTANCE: f32 : 14 * TILE_SIZE
// How long to reach jump peak (in seconds)
TIME_TO_PEAK: f32 : 0.3
// How long to reach height we jumped from (in seconds)
TIME_TO_DESCENT: f32 : 0.25
// How many pixels high can we jump
JUMP_HEIGHT: f32 : 3.25 * TILE_SIZE

max_speed := calculate_speed()
dash_speed := calculate_dash_speed()
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

calculate_speed :: proc "c" () -> f32 {
	return JUMP_DISTANCE / (TIME_TO_PEAK + TIME_TO_DESCENT)
}

calculate_dash_speed :: proc "c" () -> f32 {
	return DASH_JUMP_DISTANCE / (TIME_TO_PEAK + TIME_TO_DESCENT)
}


Player :: struct {
	using rigidbody:   Rigidbody,
	// TODO: replace input direction with Kick angles, define the kick angles for the Striker Badge
	kick_angle:        Kick_Angle,
	movement_delta:    f32,
	facing:            f32,
	carry_pos:         f32,
	state_flags:       bit_set[Player_State;u8],
	timed_state_flags: bit_set[Player_Timed_State;u8],
	flag_timers:       [Player_Timed_State]f32,
	juice_values:      [Player_Juice_Values]f32,
	badge_type:        Player_Badge,
	has_ball:          bool,
}

Player_Badge :: enum u8 {
	None,
	Striker,
	Sisyphus,
	Ghost,
}

Player_Juice_Values :: enum u8 {
	Dribble_Timer,
}

Kick_Angle :: enum u8 {
	Up,
	Forward,
	Down,
}

Player_State :: enum u8 {
	Grounded,
	Double_Jump,
	Walking,
	Dashing,
}

Player_Timed_State :: enum u8 {
	Coyote,
	Ignore_Ball,
	No_Badge,
}

Player_Master_State :: enum u16 {
	Grounded,
	Double_Jump,
	Walking,
	Dashing,
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
	case .Walking:
		contains = .Walking in world.player.state_flags
	case .Dashing:
		contains = .Dashing in world.player.state_flags
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

player_foot_position :: proc(direction: f32 = 1) -> Vec2 {
	player := &world.player
	return(
		player.translation +
		Vec2{player.facing * direction * (player.radius * 0.75), player.radius} \
	)
}

manage_juice_values :: proc(delta: f32) {
	player := &world.player
	for v in Player_Juice_Values {
		switch v {
		case .Dribble_Timer:
			dribble_timer := &player.juice_values[.Dribble_Timer]
			dribble_timer^ += delta
			// 2 radian
			if dribble_timer^ > math.PI {
				dribble_timer^ = 0
			}
		}
	}
}


manage_player_ball_flags :: proc(delta: f32) {
	player := &world.player
	ball := &world.ball
	// Player timed state flags
	for v in Player_Timed_State {
		timer := &player.flag_timers[v]
		timer^ = math.clamp(timer^ - delta, 0, 10)
		if timer^ > 0.0 {
			player.timed_state_flags += {v}
		} else {
			player.timed_state_flags -= {v}
		}
	}

	// Un-Timed state management
	if player_has(.Grounded) {
		if player.movement_delta != 0 {
			// Should use action system to allow held inputs
			if is_action_held(.Dash) {
				player.state_flags += {.Dashing}
				player.state_flags -= {.Walking}
			} else {
				player.state_flags += {.Walking}
				player.state_flags -= {.Dashing}
			}
		} else {
			player.state_flags -= {.Walking, .Dashing}
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
			unscaled_velo: Vec2
			ignore_duration: f32
			switch player.kick_angle {
			case .Up:
				ball_angle = Vec2{0, -1}
				ball.translation = player_foot_position(-1)
				unscaled_velo = {player.facing * player.radius * 2.5, 0}
				ignore_duration = 0.2
			case .Forward:
				ball_angle = Vec2{player.facing, 0} //-0.4}
				ball.flag_timers[.No_Gravity] = 0.15
				ball.translation = player_foot_position() - {0, 3}
				ignore_duration = 0.1
			case .Down:
				ball_angle = Vec2{player.facing * 0.4, -0.9}
				ball.flag_timers[.No_Gravity] = 0.15
				ball.translation = player_foot_position()
				ignore_duration = 0.2
			}

			ball.state_flags -= {.Carried}
			player.has_ball = false

			ball.velocity = (200 * ball_angle) + {player.velocity.x, 0} + unscaled_velo
			// Instead of the movement direction system, hone some specific angles:
			// - Heel kick up (Up)
			// - Normal Shot (Forward/Neutral)
			// - Low shot (Grounded, Down)
			// - Straight down shot (Airborne, Down)
			player.flag_timers[.Ignore_Ball] = ignore_duration
			player.flag_timers[.No_Badge] = 0.5
			ball.spin = player.facing
			consume_action(.Kick)
		}
	}
}

player_badge_action :: proc() {
	player := &world.player
	ball := &world.ball
	if is_action_buffered(.Badge) && !player_has(.No_Badge) {
		switch player.badge_type {
		case .None:
		case .Striker:
			if !player.has_ball {
				player.flag_timers[.No_Badge] = 1
				ball.state_flags += {.Recalling}
				consume_action(.Badge)
			}
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

player_controls :: proc() {
	player_movement()
	player_jump()
	player_kick()
	player_badge_action()
}

catch_ball :: proc() {
	player := &world.player
	ball := &world.ball
	ball.state_flags += {.Carried}
	ball.state_flags -= {.Recalling}
	ball.velocity = Vec2{0, 0}
	player.has_ball = true
}
