package main

import "core:math"
import l "core:math/linalg"


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

rigidbody_resolve_collision :: proc(
	rb: ^Rigidbody,
	collision: Collision,
	spin: f32 = 1,
	type: enum {
		Character,
		Ball,
	} = .Character,
) {

	rb.translation += collision.mtv
	x_dot := math.abs(l.dot(collision.normal, Vec2{1, 0}))
	y_dot := math.abs(l.dot(collision.normal, Vec2{0, 1}))
	if x_dot > 0.7 {
		switch type {
		case .Character:
			rb.velocity.x = 0
		case .Ball:
			rb.velocity.x *= -1
		}
	}
	if y_dot > 0.7 {
		switch type {
		case .Character:
			rb.velocity.y = 0
		case .Ball:
			// Should add some logic to convert some of balls velocity to lateral movement to simulate rolling
			y_velo := rb.velocity.y
			rb.velocity.y = y_velo * -0.6
			// Roll based on spin if our x velo is low enough
			if math.abs(rb.velocity.x) < 5 {
				rb.velocity.x = y_velo * 0.2 * spin
			}
		}
	}

}

player_ball_level_collision :: proc() {
	player := &world.player
	ball := &world.ball
	player_feet_sensor := player.translation + Vec2{0, player.radius * 1.5}
	feet_on_ground: bool
	falling := player.velocity.y > 0

	for collider in world.level_collision {
		// Player
		nearest_point := collider_nearest_point(collider, player.translation)
		head_collision, head_collided := circle_level_collide(
			player.translation - {0, player.radius / 2},
			player.radius,
			collider,
		)
		if head_collided {
			rigidbody_resolve_collision(&player.rigidbody, head_collision)
		}

		feet_collision, feet_collided := circle_level_collide(
			player.translation + {0, player.radius / 2},
			player.radius,
			collider,
		)
		if feet_collided {
			rigidbody_resolve_collision(&player.rigidbody, feet_collision)
		}
		if l.distance(nearest_point, player_feet_sensor) < 0.06 && .Standable in collider.flags {
			feet_on_ground = true
		}

		if !ball.carried {
			ball_nearest_point := collider_nearest_point(collider, ball.translation)
			ball_collision, ball_collided := circle_level_collide(
				ball.translation,
				ball.radius,
				collider,
			)
			if ball_collided {
				rigidbody_resolve_collision(&ball.rigidbody, ball_collision, ball.spin, .Ball)
			}
		}
	}
	if feet_on_ground {
		world.player.state_flags += {.Grounded, .DoubleJump}
	} else {
		player.state_flags -= {.Grounded}
	}
}
