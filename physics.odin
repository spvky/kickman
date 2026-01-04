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

apply_player_ball_gravity :: proc(delta: f32) {
	player := &world.player
	ball := &world.ball

	if player_lacks(.Riding) {
		if player.velocity.y < 0 {
			player.velocity.y += rising_gravity * delta
		} else {
			player.velocity.y += falling_gravity * delta
		}
	}

	if ball_lacks(.Carried, .Recalling, .No_Gravity) {
		if ball.velocity.y < 0 {
			ball.velocity.y += rising_gravity * delta
		} else {
			ball.velocity.y += falling_gravity * delta
		}
	}
}

player_movement :: proc(delta: f32) {
	player := &world.player
	if player.movement_delta != 0 && player_lacks(.Riding, .No_Move, .Sliding, .Crouching) {
		player.facing = player.movement_delta
		player.velocity.x = max_speed * player.movement_delta
	} else if player_has(.Crouching) && player_lacks(.Sliding) && player.movement_delta != 0 {
		player.facing = player.movement_delta
		player.velocity.x = 0
	} else if player_lacks(.No_Move, .Sliding) {
		player.velocity.x = 0
	}
}

manage_player_ball_velocity :: proc(delta: f32) {
	player := &world.player
	ball := &world.ball

	if player_has(.Sliding, .Grounded) {
		player.velocity.x *= 0.999
	}
	// Ball dribbling & recalling
	if ball_has(.Recalling) {
		player_feet := player.translation + {0, player.radius / 2}
		ball.translation = math.lerp(ball.translation, player_feet, delta * 10)
	} else if ball_has(.Carried) {
		if player_has(.Grounded) {
			if player_has(.Walking) && player_lacks(.Crouching, .Sliding) {
				dribble_position :=
					player_foot_position() +
					{
							player.facing *
							math.abs(
								math.sin(player.juice_values[.Dribble_Timer] * 5) *
								player.radius *
								1.5,
							),
							0,
						}
				ball.translation = math.lerp(ball.translation, dribble_position, delta * 50)
			} else {
				ball.translation = math.lerp(ball.translation, player_foot_position(), delta * 80)
			}
		} else {
			ball.translation = math.lerp(ball.translation, player_foot_position(), delta * 80)
		}
	} else {
		if ball_has(.Grounded) {
			if ball_has(.Revved) || player_has(.Riding) {
				ball.velocity *= 0.9999
			} else {
				ball.velocity *= 0.999
			}
		}
	}
}

apply_player_ball_velocity :: proc(delta: f32) {
	player := &world.player
	ball := &world.ball
	if player_has(.Riding) {
		player.translation = ball.translation - {0, player.radius * 2}
		player.facing = math.sign(ball.spin)
	} else {
		player.translation += (player.velocity + player.platform_velocity) * delta
	}
	if ball_lacks(.Carried, .Recalling) {
		ball.translation += ball.velocity * delta
	}
}

physics_step :: proc() {
	delta := rl.GetFrameTime()
	manage_player_ball_velocity(delta)
	manage_juice_values(delta)
	player_controls(delta)
	apply_player_ball_gravity(delta)
	apply_player_ball_velocity(delta)
	update_entities(delta)
	//Update timed flags before collision occurs
	manage_player_ball_flags(delta)
	collision_step()
}
