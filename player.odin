package main

import "core:log"
import "core:math"
import l "core:math/linalg"

Player :: struct {
	using rigidbody:            Rigidbody,
	kick_angle:                 Kick_Angle,
	queued_state:               Player_State,
	state:                      Player_State,
	prev_state:                 Player_State,
	naked_kick_angle:           Kick_Angle,
	time_to_run_speed:          f32,
	time_to_dash_speed:         f32,
	movement_delta:             f32,
	facing:                     f32,
	run_direction:              f32,
	carry_pos:                  f32,
	carry_height:               f32,
	flags:                      bit_set[Player_Flag;u16],
	timed_flags:                bit_set[Player_Timed_Flag;u16],
	standing_platform_velocity: Vec2,
	clinging_platform_velocity: Vec2,
	touching_velocity:          Vec2,
	flag_timers:                [Player_Timed_Flag]f32,
	juice_values:               [Player_Juice_Values]f32,
	badge_type:                 Player_Badge,
	speed:                      f32,
	animation:                  Animation_Player,
}

Player_Badge :: enum u8 {
	Striker,
	Sisyphus,
	Ghost,
}

Player_Juice_Values :: enum u8 {
	Dribble_Timer,
	Skid_Timer,
	Dash_Spark_Timer,
	Flourish_Timer,
	Sleep_Timer,
}

Kick_Angle :: enum u8 {
	Up,
	Forward,
	Down,
}

player_foot_position :: proc(direction: f32 = 1) -> Vec2 {
	player := &world.player
	return(
		player.translation +
		Vec2 {
				player.facing * direction * player.radius * 2,
				(player.radius + world.ball.radius) / 2.5,
			} \
	)
}

manage_player_juice_values :: proc(delta: f32) {
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
		case .Skid_Timer:
			skid_timer := &player.juice_values[.Skid_Timer]
			if player_is(.Skidding) && player.movement_delta != 0 {
				skid_timer^ += delta
				if skid_timer^ > 0.1 {
					player_skid_dust(player)
					skid_timer^ = 0.0
				}
			} else {
				skid_timer^ = 0.0
			}
		case .Dash_Spark_Timer:
			dash_spark_timer := &player.juice_values[.Dash_Spark_Timer]
			if dash_speed - math.abs(player.velocity.x) <= 5 {
				dash_spark_timer^ += delta
				if dash_spark_timer^ > 0.5 {
					// Speedlines particle
					dash_spark_timer^ = 0.0
				}
			}
		case .Flourish_Timer:
			flourish_timer := &player.juice_values[.Flourish_Timer]
			if player_is(.Idle) {
				flourish_timer^ += delta
				if flourish_timer^ >= 5 {
					flourish_timer^ = 0
					player.animation.state = .Flourish
				}
			} else {
				flourish_timer^ = 0
			}
		case .Sleep_Timer:
			sleep_timer := &player.juice_values[.Sleep_Timer]
			if player_is(.Idle) {
				sleep_timer^ += delta
				if sleep_timer^ >= 15 {
					player.animation.state = .Sleep
				}
			} else {
				sleep_timer^ = 0
			}
		}
	}
}


manage_player_flags :: proc(delta: f32) {
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
}

reset_player_touching_velo :: proc() {
	// world.player.touching_velocity = VEC_0
}

player_cling_sensors :: proc(player: ^Player) -> (sensor, empty_sensor: Circle_Collider) {
	sensor.translation =
		player.translation + {player.radius * 2 * player.facing, -player.radius * 1.5}
	sensor.radius = 3
	empty_sensor.translation =
		player.translation + {player.radius * 2 * player.facing, -player.radius * 3}
	empty_sensor.radius = 3
	return
}

player_kick :: proc() {
	player := &world.player
	ball := &world.ball
	if is_action_buffered(.Kick) {
		if player_is(.Riding) {
			// if player_can(.Dismount) {
			// 	//CHANGE ME
			// 	player.state = .Rising
			// 	ball.state = .Free
			// 	player.flag_timers[.Ignore_Ball] = 0.2
			// 	player.velocity = {player.facing * -60, -100}
			// 	player.flag_timers[.No_Control] = 0.1
			// 	ball.spin = -player.facing
			// 	ball.velocity = {player.facing * 75, -150}
			// }
		} else {
			if player_can(.Kick) {
				if player_has(.Has_Ball) && ball_lacks(.In_Collider) {
					switch player.badge_type {
					case .Striker:
						ball_angle: Vec2
						unscaled_velo: Vec2
						switch player.kick_angle {
						case .Up:
							ball_angle = Vec2{0, -1}
							ball.translation = player_foot_position(-1)
							ball.spin = player.facing
							unscaled_velo = {player.facing * player.radius * 5, -50}
							player.flag_timers[.Ignore_Ball] = 0.2
							ball.state = .Free
							ball.velocity =
								(200 * ball_angle) + {player.velocity.x, 0} + unscaled_velo
						case .Forward:
							ball_angle = Vec2{player.facing, 0} //-0.4}
							ball.flag_timers[.No_Gravity] = 0.15
							ball.state = .Free
							ball.translation = player_foot_position() - {0, 2}
							ball.spin = player.facing
							player.flag_timers[.Ignore_Ball] = 0.1
							ball.velocity =
								(200 * ball_angle) + {player.velocity.x, 0} + unscaled_velo
						case .Down:
						}
						player_remove(.Has_Ball)
						player_t_add(.Kicking, 0.3)
					case .Sisyphus:
						switch player.kick_angle {
						case .Up:
							ball.state = .Free
							player_remove(.Has_Ball)
							ball.velocity = {player.velocity.x, -300}
							player.flag_timers[.Ignore_Ball] = 0.3
						case .Forward:
							ball.state = .Free
							player_remove(.Has_Ball)
							ball.velocity = {player.velocity.x + (200 * player.facing), 0}
							player.flag_timers[.Ignore_Ball] = 0.3
						case .Down:
						}

					case .Ghost:
					}
				} else {
					//Naked Kick
					naked_kick(player)
				}
				player.flag_timers[.No_Badge] = 0.5
				consume_action(.Kick)
			}
		}
	}
}

naked_kick :: proc(player: ^Player) {
	if player_lacks(.Grounded) {
		if player.velocity.y > -75 {
			player.velocity.y = -75
		}
	}
	player.naked_kick_angle = player.kick_angle
	player_t_add(.Kicking, 0.5)
	player_t_add(.No_Turn, 0.2)
	player.juice_values[.Sleep_Timer] = 0
	player.juice_values[.Flourish_Timer] = 0
}

is_player_naked_kicking :: proc(
	player: ^Player,
) -> (
	kick_position: Vec2,
	kick_radius: f32,
	angle: Kick_Angle,
	is_kicking: bool,
) {
	if player_has(.Kicking) && player.flag_timers[.Kicking] > 0.4 {
		kick_position = player.translation + (VEC_X) * 6 * player.facing
		kick_radius = 6
		angle = player.naked_kick_angle
		is_kicking = true
	}
	return
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
				player_t_add(.No_Badge, 1)
				ball.state = .Recalling
				ball_t_add(.Recall_Rising, 0.75)
				consume_action(.Badge)
			}
		case .Sisyphus:
			if player_lacks(.No_Badge) {
				ball_dir := l.normalize0(ball.translation - player.translation)
				player.velocity += (ball_dir * 250) + {0, -100}
				ball.velocity += (-ball_dir * 150) + {0, -150}
				player_t_add(.No_Badge, 1)
				player_t_add(.Outside_Force, .5)
				consume_action(.Badge)
				log.debug("YANK")
			}
		case .Ghost:
		}
	}
}


player_jump :: proc() {
	player := &world.player
	ball := &world.ball
	if is_action_buffered(.Jump) {
		if player_is(.Riding) {
			player.velocity.y = jump_speed * 0.7
			player.velocity.x = ball.velocity.x
			player_t_add(.Ignore_Ball, 0.1)
			player_t_add(.Just_Jumped, 0.2)
			override_player_state(.Rising)
			ball.state = .Free
		} else if player_is(.Clinging) {
			player.velocity.y = jump_speed * 0.7
			player_t_add(.Just_Jumped, 0.2)
			override_player_state(.Rising)
			return
		} else {
			if player_has(.Grounded) || player_has(.Coyote) {
				player.velocity.y = jump_speed
				player.velocity += player.standing_platform_velocity
				player_remove(.Grounded)
				player_t_remove(.Coyote)
				player_t_add(.Just_Jumped, 0.15)
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

player_land :: proc() {
	player := &world.player
	make_dust(20, player.translation + VEC_Y * player.radius, -3.14, 0)
}

kill_player_oob :: proc() {
	player := &world.player
	extents := assets.room_dimensions[world.current_room]
	if player.translation.x < 0 ||
	   player.translation.x > extents.x ||
	   player.translation.y < 0 ||
	   player.translation.y > extents.y {
		spawn_player()
	}
}

handle_player_animation :: proc(delta: f32) {
	player := &world.player
	update_animation_player(&player.animation, delta)
	if player.animation.frame == 66 || player.animation.frame == 70 {
		player.carry_height = 17
	} else if player.animation.frame == 76 ||
	   player.animation.frame == 77 ||
	   player.animation.frame == 78 {
		player.carry_height = 15
	} else {
		player.carry_height = 16
	}
}

spawn_player :: proc() {
	world.current_room = world.spawn_point.room_tag
	world.player.radius = 4
	world.player.translation = world.spawn_point.position
	world.player.flags = {.Has_Ball}
	world.player.facing = 1
}
