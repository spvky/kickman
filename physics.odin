package main

import "core:log"
import "core:math"
import l "core:math/linalg"
import "core:slice"
import "tags"
import rl "vendor:raylib"

Rigidbody :: struct {
	translation: Vec2,
	velocity:    Vec2,
	radius:      f32,
}

apply_player_gravity :: proc(delta: f32) {
	player := &world.player
	ball := &world.ball

	if !player_is(.Riding, .Clinging) {
		if player_has(.Bounced) {
			if player.velocity.y < 0 {
				player.velocity.y += bounce_rising_gravity * delta
			} else {
				player.velocity.y += bounce_falling_gravity * delta
			}
		} else {
			if player.velocity.y < 0 || player_has(.Kicking) {
				player.velocity.y += rising_gravity * delta
			} else {
				player.velocity.y += falling_gravity * delta
			}
		}
	}
}

apply_ball_gravity :: proc(delta: f32) {
	ball := &world.ball

	if ball_is(.Free, .Riding) {
		if ball.velocity.y < 0 {
			ball.velocity.y += rising_gravity * delta
		} else {
			ball.velocity.y += falling_gravity * delta
		}
	}
}

player_movement :: proc(delta: f32) {
	player := &world.player
	ball := &world.ball
	heavy_carry := player.badge_type == .Sisyphus && player_has(.Has_Ball)
	if player_is(.Idle, .Running, .Crouching, .Rising, .Falling, .Riding) {
		if player.movement_delta != 0 && player_lacks(.No_Turn) {
			player.facing = player.movement_delta
		}

		if is_action_held(.Crouch) {
			player.flag_timers[.Ignore_Oneways] = 0.1
		}
	}
	switch player.state {
	case .Idle:
		player.velocity.x *= 0.99
	case .Rising, .Falling:
		if is_action_held(.Crouch) {
			player_t_add(.No_Cling, 0.1)
		}
		if math.abs(player.velocity.x) < run_speed {
			player.velocity.x +=
				(run_speed * player.movement_delta) * (delta * (1 / player.time_to_run_speed * 2))
		} else {
			if math.sign(player.movement_delta) != math.sign(player.velocity.x) {
				player.velocity.x +=
					(run_speed * player.movement_delta) *
					(delta * (1 / player.time_to_run_speed * 2))
			}
		}
	case .Running:
		if is_action_held(.Dash) && !heavy_carry {
			if math.abs(player.velocity.x) < dash_speed {
				if math.abs(player.velocity.x) < run_speed {
					player.velocity.x +=
						(run_speed * player.movement_delta) *
						(delta * (1 / player.time_to_run_speed))
				} else {
					player.velocity.x +=
						(dash_speed * player.movement_delta) *
						(delta * (1 / player.time_to_dash_speed))
				}
			}
		} else {
			if math.abs(player.velocity.x) < run_speed {
				player.velocity.x +=
					(run_speed * player.movement_delta) * (delta * (1 / player.time_to_run_speed))
			} else if math.abs(player.velocity.x) > run_speed {
				player.velocity.x *= 0.999
			}
		}
	case .Skidding:
		if player.movement_delta == -math.sign(player.velocity.x) {
			player.facing = player.movement_delta
		}
	case .Sliding:
	case .Crouching:
	case .Riding:
	case .Clinging:
		if is_action_held(.Crouch) {
			override_player_state(.Falling)
			player_t_add(.No_Cling, 0.15)
		}
	}
}

manage_player_velocity :: proc(delta: f32) {
	player := &world.player
	ball := &world.ball
	switch player.state {
	case .Idle, .Running:
	case .Crouching:
		player.velocity.x *= 0.98
	case .Skidding:
		player.velocity.x *= 0.997
		if math.abs(player.velocity.x) < 10 {
			if player.movement_delta == 0 {
				player.state = .Idle
				player.velocity.x = 0
			} else {
				player.state = .Running
			}
		}
	case .Sliding:
		player.velocity.x *= 0.999
	case .Riding:
		player.velocity = VEC_0
		player.translation = ball.translation - {0, ball.radius + player.radius}
	case .Rising:
		flag_to_check: Player_Master_Flag = player_has(.Bounced) ? .Just_Bounced : .Just_Jumped
		if !is_action_held(.Jump) && player_lacks(flag_to_check) && player_lacks(.Kicking) {
			player.velocity.y = 0
		}
	case .Falling:
	case .Clinging:
	}
}

manage_ball_velocity :: proc(delta: f32) {
	player := &world.player
	ball := &world.ball
	switch player.badge_type {
	case .Striker:
		switch ball.state {
		case .Carried:
			ball.velocity = VEC_0
			if player_is(.Running) && player_has(.Grounded) {
				dashing := is_action_held(.Dash)
				pulse: f32 = dashing ? 2.5 : 5
				amp: f32 = dashing ? 5 : 2.5
				dribble_position :=
					player_foot_position() +
					{
							player.facing *
							math.abs(
								math.sin((player.juice_values[.Dribble_Timer]) * 5 + pulse) *
								player.radius *
								amp,
							),
							0,
						}
				ball.translation = math.lerp(ball.translation, dribble_position, delta * 50)
			} else {
				ball.translation = math.lerp(ball.translation, player_foot_position(), delta * 80)
			}
		case .Free:
			if ball_has(.Grounded) {
				ball.velocity.x *= 0.999
			}
		case .Recalling:
			ball.velocity = VEC_0
			if ball_has(.Recall_Rising) {
				ball.translation.y -= 16 * delta
			} else {
				player_feet := player.translation + {0, player.radius / 2}
				if l.distance(ball.translation, player.translation) > 12 {
					ball.translation = math.lerp(ball.translation, player_feet, delta * 20)
				} else {
					ball.translation = player_feet
				}
			}
		case .Riding:
		}
	case .Sisyphus:
		#partial switch ball.state {
		case .Carried:
			ball.translation = player.translation - (VEC_Y * world.player.carry_height)
		case .Free:
			ball.rotation += delta * (ball.velocity.x / 100) * 360
			if ball_has(.Grounded) {
				ball.velocity.x *= 0.9999
			}
		case .Riding:
			if player.movement_delta != 0 {
				velo_to_add := player.movement_delta * 200 * delta
				matching_sign := math.sign(player.movement_delta) == math.sign(ball.velocity.x)
				if math.abs(ball.velocity.x) < 300 {
					ball.velocity.x += velo_to_add
				} else if !matching_sign {
					ball.velocity.x *= 0.99
					ball.velocity.x += velo_to_add
				}
			} else {
				if ball_has(.Grounded) {
					ball.velocity.x *= 0.9999
				}
			}
			ball.rotation += delta * (ball.velocity.x / 100) * 360
		}
	case .Ghost:
	}
}

apply_player_velocity :: proc(delta: f32) {
	player := &world.player
	player.translation += (player.velocity + player.standing_platform_velocity) * delta
}

apply_ball_velocity :: proc(delta: f32) {
	ball := &world.ball
	if ball_is(.Free, .Riding) {
		ball.translation += ball.velocity * delta
	}
}

dynamics_step :: proc(delta: f32) {
	manage_player_velocity(delta)
	manage_ball_velocity(delta)

	player_controls(delta)

	apply_player_gravity(delta)
	apply_ball_gravity(delta)

	apply_player_velocity(delta)
	apply_ball_velocity(delta)
}
