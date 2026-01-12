package main

import "core:log"
import "core:math"


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

run_speed := calculate_ground_speed()
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

calculate_ground_speed :: proc "c" () -> f32 {
	return JUMP_DISTANCE / (TIME_TO_PEAK + TIME_TO_DESCENT)
}

calculate_dash_speed :: proc "c" () -> f32 {
	return DASH_JUMP_DISTANCE / (TIME_TO_PEAK + TIME_TO_DESCENT)
}


Player :: struct {
	using rigidbody:    Rigidbody,
	kick_angle:         Kick_Angle,
	queued_state:       Player_State,
	state:              Player_State,
	prev_state:         Player_State,
	time_to_run_speed:  f32,
	time_to_dash_speed: f32,
	movement_delta:     f32,
	facing:             f32,
	run_direction:      f32,
	carry_pos:          f32,
	flags:              bit_set[Player_Flag;u8],
	timed_flags:        bit_set[Player_Timed_Flag;u8],
	platform_velocity:  Vec2,
	flag_timers:        [Player_Timed_Flag]f32,
	juice_values:       [Player_Juice_Values]f32,
	badge_type:         Player_Badge,
	speed:              f32,
}

Player_Badge :: enum u8 {
	Striker,
	Sisyphus,
	Ghost,
}

Player_Juice_Values :: enum u8 {
	Dribble_Timer,
	Skid_Timer,
}

Kick_Angle :: enum u8 {
	Up,
	Forward,
	Down,
}

Ball :: struct {
	using rigidbody: Rigidbody,
	ignore_player:   f32,
	spin:            f32,
	state:           Ball_State,
	flags:           bit_set[Ball_Flag;u8],
	timed_flags:     bit_set[Ball_Timed_Flag;u8],
	flag_timers:     [Ball_Timed_Flag]f32,
	juice_values:    [Ball_Juice_Values]f32,
}

Ball_Juice_Values :: enum {
	Rev_Flash,
}

player_foot_position :: proc(direction: f32 = 1) -> Vec2 {
	player := &world.player
	return(
		player.translation +
		Vec2 {
				player.facing * direction * player.radius,
				(player.radius + world.ball.radius) / 2.5,
			} \
	)
}

manage_juice_values :: proc(delta: f32) {
	player := &world.player
	ball := &world.ball
	for v in Player_Juice_Values {
		switch v {
		case .Dribble_Timer:
			dribble_timer := &player.juice_values[.Dribble_Timer]
			dribble_timer^ += delta
			// 2 radian
			if dribble_timer^ > math.PI {
				dribble_timer^ = 0
			}
		case .Skid_Timer:
			skid_timer := &player.juice_values[.Dribble_Timer]
			if player_is(.Skidding) {
				skid_timer^ += delta
				if skid_timer^ > 0.2 {
					player_skid_dust(player)
					skid_timer^ = 0.0
				}
			} else {
				skid_timer^ = 0.0
			}
		}
	}

	for v in Ball_Juice_Values {
		switch v {
		case .Rev_Flash:
			rev_timer := &ball.juice_values[.Rev_Flash]
			rev_timer^ += delta
			if rev_timer^ > math.PI {
				rev_timer^ = 0
			}
		}
	}
}


manage_player_ball_flags :: proc(delta: f32) {
	player := &world.player
	ball := &world.ball
	// Player timed state flags
	for v in Player_Timed_Flag {
		timer := &player.flag_timers[v]
		timer^ = math.clamp(timer^ - delta, 0, 10)
		if timer^ > 0.0 {
			player.timed_flags += {v}
		} else {
			player.timed_flags -= {v}
		}
	}

	for v in Ball_Timed_Flag {
		timer := &ball.flag_timers[v]
		timer^ = math.clamp(timer^ - delta, 0, 10)
		if timer^ > 0.0 {
			ball.timed_flags += {v}
		} else {
			ball.timed_flags -= {v}
		}
	}
}

player_kick :: proc() {
	player := &world.player
	ball := &world.ball
	if is_action_buffered(.Kick) {
		if player_is(.Riding) {
			if player_can(.Dismount) {
				//CHANGE ME
				player.state = .Rising
				ball.state = .Free
				player.flag_timers[.Ignore_Ball] = 0.2
				player.velocity = {player.facing * -60, -100}
				player.flag_timers[.No_Control] = 0.1
				ball.spin = -player.facing
				ball.velocity = {player.facing * 75, -150}
			}
		} else {
			if player_can(.Kick) {
				ball_angle: Vec2
				unscaled_velo: Vec2
				switch player.kick_angle {
				case .Up:
					ball_angle = Vec2{0, -1}
					ball.translation = player_foot_position(-1)
					ball.spin = player.facing
					unscaled_velo = {player.facing * player.radius * 2.5, -50}
					player.flag_timers[.Ignore_Ball] = 0.2
					ball.state = .Free
					ball.velocity = (200 * ball_angle) + {player.velocity.x, 0} + unscaled_velo
				case .Forward:
					ball_angle = Vec2{player.facing, 0} //-0.4}
					ball.flag_timers[.No_Gravity] = 0.15
					ball.state = .Free
					ball.translation = player_foot_position() - {0, 2}
					ball.spin = player.facing
					player.flag_timers[.Ignore_Ball] = 0.1
					ball.velocity = (200 * ball_angle) + {player.velocity.x, 0} + unscaled_velo
				case .Down:
					ball.spin = player.facing
					ball.state = .Revved
					ball.translation = player_foot_position()
					player.flag_timers[.Ignore_Ball] = 0.3
					ball.velocity = {-player.facing * 30, -175} + {player.velocity.x, 0}
				}
				player.flags -= {.Has_Ball}
				player.flag_timers[.No_Badge] = 0.5
				consume_action(.Kick)
			}
		}
	}
}

player_slide :: proc() {
	player := &world.player
	if player_can(.Slide) {
		if is_action_buffered(.Slide) {
			player.flag_timers[.In_Slide] = 0.55
			player.velocity.x = run_speed * 2 * player.facing
		}
	}
}

player_badge_action :: proc() {
	player := &world.player
	ball := &world.ball
	if is_action_buffered(.Badge) {
		switch player.badge_type {
		case .Striker:
			if player_can(.Recall) {
				player.flag_timers[.No_Badge] = 1
				ball.state = .Recalling
				consume_action(.Badge)
			}
		case .Sisyphus:
		case .Ghost:
		}
	}
}


player_jump :: proc() {
	player := &world.player
	ball := &world.ball
	if is_action_buffered(.Jump) {
		if player_is(.Riding) && ball_is(.Riding) {
			if ball_has(.Grounded) || ball_has(.Coyote) {
				ball.velocity.y = jump_speed
				ball.timed_flags -= {.Coyote}
				consume_action(.Jump)
				return
			}
		} else {
			if player_has(.Grounded) || player_has(.Coyote) {

				player.velocity.y = jump_speed
				player.velocity += player.platform_velocity
				player_remove(.Grounded)
				player_t_remove(.Coyote)
				player_t_add(.Bounced, 0.15)
				consume_action(.Jump)
				player_jump_dust(player)
				return
			}
		}
	}
}

player_skid_dust :: proc(player: ^Player) {
	dust_min_angle, dust_max_angle: f32
	if player.velocity.x <= -5 {
		dust_min_angle = -3.14
		dust_max_angle = -1.92
	} else if player.velocity.x >= 5 {
		dust_min_angle = -1.07
		dust_max_angle = 0
	}
	slide_dir := math.sign(player.velocity.x)
	make_sparks(
		5,
		player.translation + (VEC_Y * player.radius) + (VEC_X * slide_dir * 6),
		dust_min_angle,
		dust_max_angle,
		slide_dir,
	)
}

player_jump_dust :: proc(player: ^Player) {
	dust_min_angle, dust_max_angle: f32
	if math.abs(player.velocity.x) < 5 {
		dust_min_angle = -1.92
		dust_max_angle = -0.22
	} else if player.velocity.x >= 5 {
		dust_min_angle = -3.14
		dust_max_angle = -1.92
	} else if player.velocity.x <= 5 {
		dust_min_angle = -1.07
		dust_max_angle = 0
	}
	make_dust(5, player.translation + VEC_Y * player.radius, dust_min_angle, dust_max_angle)
}

player_controls :: proc(delta: f32) {
	player_jump()
	player_kick()
	player_slide()
	player_badge_action()
	player_movement(delta)
}

catch_ball :: proc() {
	player := &world.player
	ball := &world.ball
	ball.state = .Carried
	ball.flags -= {.Bounced}
	ball.velocity = Vec2{0, 0}
	ball.translation = player_foot_position()
	player.flags += {.Has_Ball}
}

player_land :: proc() {
	player := &world.player
	make_dust(20, player.translation + VEC_Y * player.radius, -3.14, 0)
}
