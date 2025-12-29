package main

import "core:log"
import "core:math"
import l "core:math/linalg"
import rl "vendor:raylib"

Rigidbody :: struct {
	translation: Vec2,
	velocity:    Vec2,
	radius:      f32,
}

apply_player_ball_gravity :: proc(delta: f32) {
	player := &world.player
	ball := &world.ball

	if player.velocity.y < 0 {
		player.velocity.y += rising_gravity * delta
	} else {
		player.velocity.y += falling_gravity * delta
	}

	if !ball_has(.Carried) && !ball_has(.Recalling) && !ball_has(.No_Gravity) {
		if ball.velocity.y < 0 {
			ball.velocity.y += rising_gravity * delta
		} else {
			ball.velocity.y += falling_gravity * delta
		}
	}
}

player_movement :: proc() {
	player := &world.player
	if player.movement_delta != 0 {
		if player_has(.Dashing) {
			player.velocity.x = dash_speed * player.movement_delta
		} else {
			player.velocity.x = max_speed * player.movement_delta
		}
	} else {
		// This will eventually only zero out x velocity when able to move
		player.velocity.x = 0
	}
}

manage_player_ball_velocity :: proc(delta: f32) {
	player := &world.player
	ball := &world.ball
	if ball_has(.Recalling) {
		player_feet := player.translation + {0, player.radius / 2}
		ball.translation = math.lerp(ball.translation, player_feet, delta * 10)
	} else if ball_has(.Carried) {

		// time := f32(rl.GetTime())
		if player_has(.Grounded) {
			if player_has(.Walking) {
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
			} else if player_has(.Dashing) {
				dribble_position :=
					player_foot_position() +
					{
							player.facing *
							math.abs(
								math.sin(player.juice_values[.Dribble_Timer] * 4) *
								player.radius *
								3,
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
			ball.velocity *= 0.999
		}
	}
}

apply_player_ball_velocity :: proc(delta: f32) {
	player := &world.player
	ball := &world.ball
	player.translation += player.velocity * delta
	if !ball_has(.Carried) && !ball_has(.Recalling) {
		ball.translation += ball.velocity * delta
	}
}

physics_step :: proc() {
	delta := rl.GetFrameTime()
	manage_player_ball_velocity(delta)
	manage_juice_values(delta)
	player_controls()
	apply_player_ball_gravity(delta)
	apply_player_ball_velocity(delta)
	//Update timed flags before collision occurs
	manage_player_ball_flags(delta)
	player_ball_level_collision()
	player_ball_collision()
}

// Collision

Level_Collider :: struct {
	using aabb: AABB,
	flags:      bit_set[Collider_Flag;u8],
}

AABB :: struct {
	min, max: Vec2,
}

Collider_Flag :: enum u8 {
	Standable,
	Clingable,
	Oneway,
}

Collision :: struct {
	normal: Vec2,
	mtv:    Vec2,
}

aabb_nearest_point :: proc(c: AABB, v: Vec2) -> Vec2 {
	return l.clamp(v, c.min, c.max)
}

circle_level_collide :: proc(
	translation: Vec2,
	radius: f32,
	collider: Level_Collider,
) -> (
	collision: Collision,
	ok: bool,
) {
	nearest_point := aabb_nearest_point(collider.aabb, translation)
	if l.distance(nearest_point, translation) < radius {
		collision_vector := translation - nearest_point
		collision.normal = l.normalize0(collision_vector)
		pen_depth := radius - l.length(collision_vector)
		collision.mtv = collision.normal * pen_depth
		ok = true
	}
	return
}

circle_sensor_level_collider_overlap :: proc(
	translation: Vec2,
	radius: f32,
	collider: Level_Collider,
	collider_mask: bit_set[Collider_Flag;u8],
) -> (
	overlap: bool,
) {
	if collider.flags <= collider_mask {
		nearest_point := aabb_nearest_point(collider.aabb, translation)
		overlap = l.distance(nearest_point, translation) < radius
	}
	return
}

player_resolve_level_collision :: proc(player: ^Player, collision: Collision, spin: f32 = 1) {
	player.translation += collision.mtv
	x_dot := math.abs(l.dot(collision.normal, Vec2{1, 0}))
	y_dot := math.abs(l.dot(collision.normal, Vec2{0, 1}))
	if x_dot > 0.7 {
		player.velocity.x = 0
	}
	if y_dot > 0.7 {
		player.velocity.y = 0
	}
}

ball_resolve_level_collision :: proc(ball: ^Ball, collision: Collision) {
	ball.translation += collision.mtv
	x_dot := math.abs(l.dot(collision.normal, Vec2{1, 0}))
	y_dot := math.abs(l.dot(collision.normal, Vec2{0, 1}))
	if x_dot > 0.7 {
		ball.velocity.x *= -0.9
		ball.spin *= -1
	}
	if y_dot > 0.7 {
		y_velo := ball.velocity.y
		ball.velocity.y = y_velo * -0.6
		// Roll based on spin if our x velo is low enough
		if math.abs(ball.velocity.x) < 5 {
			ball.velocity.x = y_velo * 0.2 * ball.spin
		}
	}
}

player_ball_level_collision :: proc() {
	player := &world.player
	ball := &world.ball
	player_feet_sensor := player.translation + Vec2{0, player.radius * 1.5}
	feet_on_ground, ball_on_ground: bool
	falling := player.velocity.y > 0

	for collider in assets.room_collision[world.current_room].room_collision {
		// Player
		head_collision, head_collided := circle_level_collide(
			player.translation - {0, player.radius / 2},
			player.radius,
			collider,
		)
		if head_collided {
			player_resolve_level_collision(player, head_collision)
		}

		feet_collision, feet_collided := circle_level_collide(
			player.translation + {0, player.radius / 2},
			player.radius,
			collider,
		)
		if feet_collided {
			player_resolve_level_collision(player, feet_collision)
		}
		if circle_sensor_level_collider_overlap(player_feet_sensor, 0.06, collider, {.Standable}) {
			feet_on_ground = true
			player.flag_timers[.Coyote] = 0.10
		}

		// Ball
		if !ball_has(.Carried) && !ball_has(.Recalling) {
			ball_ground_sensor := ball.translation + Vec2{0, ball.radius}
			ball_collision, ball_collided := circle_level_collide(
				ball.translation,
				ball.radius,
				collider,
			)
			if ball_collided {
				ball_resolve_level_collision(ball, ball_collision)
			}
			
					//odinfmt: disable
			if circle_sensor_level_collider_overlap( ball_ground_sensor, 0.06, collider, {.Standable}) {
				ball_on_ground = true
			}
			//odinfmt: enable
		}
	}
	if feet_on_ground {
		player.state_flags += {.Grounded, .Double_Jump}
	} else {
		player.state_flags -= {.Grounded}
	}

	if ball_on_ground && !ball_has(.No_Gravity) && !ball_has(.Recalling) {
		ball.state_flags += {.Grounded}
	} else {
		ball.state_flags -= {.Grounded}
	}
}

player_ball_collision :: proc() {
	player := &world.player
	ball := &world.ball
	if !player_has(.Ignore_Ball) && !ball_has(.Carried) {
		// Header
		// Define specific head angles based on how close the ball is to the center of the player:
		// Center - straight up with the characters x momentum
		player_head := player.translation - {0, player.radius / 2}
		ball_above_head := ball.translation.y < player_head.y
		player_feet := player.translation + {0, player.radius / 2}
		player_bounce_box := AABB {
			player.translation - {player.radius * 1.5, 0},
			player.translation + ({player.radius * 1.5, player.radius * 2}),
		}
		if !ball_has(.Recalling) {
			if l.distance(player_head, ball.translation) < player.radius + ball.radius {
				ball_magnitude := l.length(ball.velocity)
				player_magnitude := l.length(player.velocity)
				head_normal := l.normalize0(ball.translation - player_head)
				ball.velocity = ((ball_magnitude * 0.9) + (player_magnitude * 0.5)) * head_normal
				player.flag_timers[.Ignore_Ball] = 0.2
			}
			ball_bounce_nearest := aabb_nearest_point(player_bounce_box, ball.translation)
			if l.distance(ball_bounce_nearest, ball.translation) < ball.radius {
				if player_has(.Grounded) || l.length(ball.velocity) <= 1 {
					catch_ball()
				} else {
					// Ball Jump
					player.velocity.y = jump_speed
					player.translation.y = ball.translation.y - ball.radius - (player.radius * 1.5)
					player.flag_timers[.Ignore_Ball] = 0.2
					ball_mag := l.length(ball.velocity)
					ball.velocity = ball_mag * Vec2{0, 1}
				}
			}
		} else {
			if l.distance(player_feet, ball.translation) < player.radius + ball.radius {
				catch_ball()
			}
		}
	}
}
