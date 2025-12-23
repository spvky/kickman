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

	if !ball.carried {
		if ball.velocity.y < 0 {
			ball.velocity.y += rising_gravity * delta
		} else {
			ball.velocity.y += falling_gravity * delta
		}
	}
}

manage_player_ball_velocity :: proc() {
	ball := &world.ball
	if .Grounded in ball.state_flags {
		ball.velocity *= 0.998
	}
}

apply_player_ball_velocity :: proc(delta: f32) {
	world.player.translation += world.player.velocity * delta
	if !world.ball.carried {
		world.ball.translation += world.ball.velocity * delta
	}
}

physics_step :: proc() {
	delta := rl.GetFrameTime()
	manage_player_ball_velocity()
	manage_ignore_ball(delta)
	player_jump()
	player_kick()
	apply_player_ball_gravity(delta)
	apply_player_ball_velocity(delta)
	player_ball_level_collision()
	player_ball_collision()
}

// Collision

Level_Collider :: struct {
	max:   Vec2,
	min:   Vec2,
	flags: bit_set[Collider_Flag;u8],
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

collider_nearest_point :: proc(c: Level_Collider, v: Vec2) -> Vec2 {
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
	nearest_point := collider_nearest_point(collider, translation)
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
		nearest_point := collider_nearest_point(collider, translation)
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
		ball.velocity.x *= -1
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

	for collider in world.level_collision {
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
		}

		// Ball
		if !ball.carried {
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
		player.state_flags += {.Grounded, .DoubleJump}
	} else {
		player.state_flags -= {.Grounded}
	}

	if ball_on_ground {
		ball.state_flags += {.Grounded}
	} else {
		ball.state_flags -= {.Grounded}
	}
}

player_ball_collision :: proc() {
	player := &world.player
	ball := &world.ball
	if player.ignore_ball == 0 && !ball.carried {
		// Header
		player_head := player.translation - {0, player.radius / 2}
		if l.distance(player_head, ball.translation) < (player.radius * 0.75) + ball.radius {
			ball_magnitude := l.length(ball.velocity)
			player_magnitude := l.length(player.velocity)
			head_normal := l.normalize0(ball.translation - player_head)
			ball.velocity = ((ball_magnitude * 0.9) + (player_magnitude * 0.5)) * head_normal
			player.ignore_ball = 0.2
		}
		player_feet := player.translation + {0, player.radius / 2}
		if l.distance(player_feet, ball.translation) < player.radius + ball.radius {
			log.info("Foot collision")
			catch_ball()
		}
	}
}
