package main

import "core:log"
import "core:math"
import l "core:math/linalg"
import "core:slice"
import "tags"

Collider :: struct {
	using aabb: AABB,
	flags:      bit_set[tags.Collider_Flag;u8],
	velocity:   Vec2,
}

AABB :: struct {
	min, max: Vec2,
}

Collision :: struct {
	normal: Vec2,
	mtv:    Vec2,
}

aabb_nearest_point :: proc(c: AABB, v: Vec2) -> Vec2 {
	return l.clamp(v, c.min, c.max)
}

circle_aabb_collide :: proc(
	translation: Vec2,
	radius: f32,
	bb: AABB,
) -> (
	collision: Collision,
	ok: bool,
) {
	nearest_point := aabb_nearest_point(bb, translation)
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
	collider: Collider,
	collider_mask: bit_set[tags.Collider_Flag;u8],
) -> (
	overlap: bool,
) {
	if collider.flags <= collider_mask {
		nearest_point := aabb_nearest_point(collider.aabb, translation)
		overlap = l.distance(nearest_point, translation) < radius
	}
	return
}

player_resolve_level_collision :: proc(player: ^Player, collision: Collision) {
	player.translation += collision.mtv
	x_dot := math.abs(l.dot(collision.normal, Vec2{1, 0}))
	y_dot := math.abs(l.dot(collision.normal, Vec2{0, 1}))
	if x_dot > 0.7 {
		player.velocity.x = 0
		if player_has(.Grounded) {
			player.flags -= {.Walking}
		}
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
		ball.spin = -1 * math.sign(ball.spin)
	}
	if y_dot > 0.7 {
		y_velo := ball.velocity.y
		if ball_has(.Revved) {
			ball.velocity.y = y_velo * -0.3
		} else {
			ball.velocity.y = y_velo * -0.6
		}
		// Roll based on spin if our x velo is low enough
		if math.abs(ball.velocity.x) < 25 && ball_lacks(.Revved) {
			ball.velocity.x = y_velo * 0.2 * ball.spin
		} else if ball_has(.Revved) && ball_lacks(.Bounced) {
			// If Revved and hasn't bounced yet apply rev speed
			ball.velocity.x = 300 * ball.spin
		}
		ball.flags += {.Bounced}
	}
}

player_ball_transition_collision :: proc() {
	player := &world.player
	ball := &world.ball
	for transition in assets.room_transitions[world.current_room] {
		// Player Collision
		if player_lacks(.No_Transition) {
			if _, player_collided := circle_aabb_collide(
				player.translation,
				player.radius / 2,
				transition.aabb,
			); player_collided {
				transition_extents := transition.max - transition.min
				translation_ptr: ^Vec2

				if player_has(.Riding) {
					translation_ptr = &ball.translation
				} else {
					translation_ptr = &player.translation
				}

				if transition_extents.x < transition_extents.y {
					y_offset := translation_ptr.y - (transition.max.y + transition.min.y) / 2
					translation_ptr.x = transition.transition_position.x
					translation_ptr.y = transition.transition_position.y + y_offset
				} else {
					x_offset := translation_ptr.x - (transition.max.x + transition.min.x) / 2
					translation_ptr.y = transition.transition_position.y
					translation_ptr.x = transition.transition_position.x + x_offset
				}

				if player_lacks(.Riding) {
					catch_ball()
				}

				world.current_room = transition.tag
				player.flag_timers[.No_Transition] = 0.2
			}
		}

		//Ball
		if player_lacks(.Riding) {
			if collision, ball_collided := circle_aabb_collide(
				ball.translation,
				ball.radius,
				transition.aabb,
			); ball_collided {
				ball_resolve_level_collision(ball, collision)
			}
		}
	}
}

player_ball_level_collision :: proc() {
	player := &world.player
	ball := &world.ball
	player_feet_sensor := player.translation + Vec2{0, player.radius * 1.5}
	platform_velocity: Vec2
	feet_on_ground, ball_on_ground, ball_in_collider: bool
	falling := player.velocity.y > 0

	entity_colliders := make([dynamic]Collider, 0, 4, allocator = context.temp_allocator)
	for entity in assets.room_entities[world.current_room] {
		if entity.tag == .Movable_Block {
			data := entity.data.(tags.Movable_Block_Data)
			collider := Collider {
				min      = entity.pos,
				max      = entity.pos + data.extents,
				flags    = {.Standable},
				velocity = data.velocity,
			}
			append(&entity_colliders, collider)
		}
	}

	collision_slice: []Collider = slice.concatenate(
		[][]Collider{assets.room_collision[world.current_room][:], entity_colliders[:]},
		allocator = context.temp_allocator,
	)

	for collider in collision_slice {
		// Player

		player_should_collide := true
		ball_should_collide := true

		if .Oneway in collider.flags {

			if player.velocity.y <= 0 ||
			   collider.min.y < player.translation.y + (player.radius * 1.4) {
				player_should_collide = false
			}

			if ball.velocity.y <= 0 {if collider.min.y < ball.translation.y + ball.radius {
					ball_should_collide = false
				}
			}
		}

		if player_lacks(.Riding, .Sliding) && player_should_collide {
			head_collision, head_collided := circle_aabb_collide(
				player.translation - {0, player.radius / 2},
				player.radius,
				collider.aabb,
			)
			if head_collided && .Oneway not_in collider.flags {
				//TODO: Head collision while riding
				player_resolve_level_collision(player, head_collision)
			}
		}

		if player_lacks(.Riding) && player_should_collide {
			feet_collision, feet_collided := circle_aabb_collide(
				player.translation + {0, player.radius / 2},
				player.radius,
				collider.aabb,
			)
			if feet_collided {
				player_resolve_level_collision(player, feet_collision)

			}
		}
		if circle_sensor_level_collider_overlap(
			player_feet_sensor,
			1,
			collider,
			{.Standable, .Oneway},
		) {
			feet_on_ground = true
			platform_velocity.x =
				abs(platform_velocity.x) > abs(collider.velocity.x) ? platform_velocity.x : collider.velocity.x
			platform_velocity.y =
				abs(platform_velocity.y) > abs(collider.velocity.y) ? platform_velocity.y : collider.velocity.y
		}

		// Ball
		if ball_should_collide {
			ball_ground_sensor := ball.translation + Vec2{0, ball.radius}
			ball_collision, ball_collided := circle_aabb_collide(
				ball.translation,
				ball.radius,
				collider.aabb,
			)
			if ball_collided {
				if ball_lacks(.Carried, .Recalling) {
					ball_resolve_level_collision(ball, ball_collision)
				} else {
					ball_in_collider = true
				}
			}
			
					//odinfmt: disable
			if circle_sensor_level_collider_overlap( ball_ground_sensor, 0.06, collider, {.Standable}) {
				ball_on_ground = true
			}
			//odinfmt: enable
		}
	}
	if feet_on_ground {
		player.flags += {.Grounded, .Double_Jump}
		player.flag_timers[.Coyote] = 0.10
		player.platform_velocity = {platform_velocity.x, platform_velocity.y * 0.3}
	} else {
		player.flags -= {.Grounded}
	}

	if ball_on_ground && ball_lacks(.No_Gravity, .Recalling) {
		ball.flags += {.Grounded}
		ball.flag_timers[.Coyote] = 0.10
	} else {
		ball.flags -= {.Grounded}
	}

	if ball_in_collider {
		ball.flags += {.In_Collider}
	} else {
		ball.flags -= {.In_Collider}
	}
}

player_ball_entity_collision :: proc() {
	player := &world.player
	ball := &world.ball
	for &entity in assets.room_entities[world.current_room] {
		switch entity.tag {
		case .Lever:
			bb := AABB {
				min = entity.pos,
				max = entity.pos + {8, 8},
			}
			data := &entity.data.(tags.Trigger_Data)
			already_touching := data.touching_player
			player_colliding: bool
			ball_colliding: bool
			_, player_colliding = circle_aabb_collide(player.translation, player.radius, bb)
			if ball_lacks(.Recalling) {
				_, ball_colliding = circle_aabb_collide(ball.translation, ball.radius, bb)
			}
			touching_this_frame := player_colliding || ball_colliding
			if !already_touching && touching_this_frame {
				data.on = !data.on
			}
			data.touching_player = touching_this_frame
		case .Button:
			bb := AABB {
				min = entity.pos,
				max = entity.pos + {8, 8},
			}
		case .Movable_Block:
			data := entity.data.(tags.Movable_Block_Data)
			bb := AABB {
				min = entity.pos,
				max = entity.pos + data.extents,
			}
		}
	}
}

player_ball_collision :: proc() {
	player := &world.player
	ball := &world.ball
	if player_ball_can_interact() {
		// Calculate player hitboxes for ball interactions
		player_head := player.translation - {0, player.radius / 2}
		ball_above_head := ball.translation.y < player_head.y
		player_feet := player.translation + {0, player.radius / 2}
		player_bounce_box := AABB {
			player.translation - {player.radius * 1.5, player.radius * 0.25},
			player.translation + ({player.radius * 1.5, player.radius * 2}),
		}

		if player_can(.Header) {
			if l.distance(player_head, ball.translation) < player.radius + ball.radius {
				ball_magnitude := l.length(ball.velocity)
				player_magnitude := l.length(player.velocity)
				head_normal := l.normalize0(ball.translation - player_head)
				ball.velocity = ((ball_magnitude * 0.9) + (player_magnitude * 0.5)) * head_normal
				player.flag_timers[.Ignore_Ball] = 0.2
				ball.flags += {.Bounced}
				return
			}
		}
		ball_feet_nearest := aabb_nearest_point(player_bounce_box, ball.translation)
		feet_touching_ball := l.distance(ball_feet_nearest, ball.translation) < ball.radius

		if feet_touching_ball {
			if player_can(.Bounce) {
				ball.velocity.y = player.velocity.y
				ball.velocity.x *= 0.3 * player.facing
				ball.spin = player.facing
				player.velocity.y = jump_speed * 1.125
				player.translation.y = ball.translation.y - ball.radius - (player.radius * 1.5)
				player.flag_timers[.Ignore_Ball] = 0.2
				return
			}

			if player_can(.Ride) {
				player.flags += {.Riding}
				player.flags -= {.Crouching}
				ball.flags -= {.Revved}
				return
			}

			if player_can(.Catch) {
				catch_ball()
			}
		}
	}
}

collision_step :: proc() {
	player_ball_level_collision()
	player_ball_entity_collision()
	player_ball_transition_collision()
	player_ball_collision()
}
