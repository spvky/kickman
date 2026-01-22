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

Circle_Collider :: struct {
	translation: Vec2,
	radius:      f32,
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
		if ball_is(.Revved) {
			ball.velocity.y = ball.velocity.y * -0.3
			if ball_lacks(.Bounced) {
				ball.velocity.x = 300 * ball.spin
			}
		} else {
			ball.velocity.y = ball.velocity.y * -0.6
		}
		ball.flags += {.Bounced}
	}
}

player_ball_transition_collision :: proc() {
	player := &world.player
	ball := &world.ball
	for &transition in assets.room_transitions[world.current_room] {
		// Player Collision
		if _, player_collided := circle_aabb_collide(
			player.translation,
			player.radius / 2,
			transition.aabb,
		); player_collided {

			if player_has(.No_Transition) {
				transition.touching_player = true
			} else if transition.active {
				transition_extents := transition.max - transition.min
				translation_ptr: ^Vec2

				if player_is(.Riding) {
					log.debugf("Hit transition while riding: %v", world.current_room)
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

				// if !player_is(.Riding) {
				// 	// catch_ball()
				// }

				set_room(transition.tag)
				player_t_add(.No_Transition, 0.2)
				clear_dust()
			}
		} else {
			transition.touching_player = false
		}

		//Ball
		if !ball_is(.Riding) {
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

player_tooltip_collision :: proc() {
	player := &world.player
	for &tt in assets.room_tooltips[world.current_room] {
		tooltip_aabb := AABB {
			min = tt.pos,
			max = tt.pos + tt.extents,
		}
		// Player Collision
		if _, player_collided := circle_aabb_collide(
			player.translation,
			player.radius / 2,
			tooltip_aabb,
		); player_collided {
			tt.touching_player = true
		} else {
			tt.touching_player = false
		}
	}
}

player_static_collision :: proc(collider: Collider, on_ground: ^bool) {
	player := &world.player
	player_feet_sensor := player.translation + Vec2{0, player.radius * 1.5}
	player_should_collide := true
	platform_velocity: Vec2
	kick_pos, kick_radius, _, is_hitbox_active := player_kick_hitbox(player)


	if .Oneway in collider.flags {
		is_hitbox_active = false
		if player.velocity.y <= 0 ||
		   collider.min.y < player.translation.y + (player.radius * 1.4) ||
		   player_has(.Ignore_Oneways) {
			player_should_collide = false
		}
	}

	// Kick Collision
	if is_hitbox_active && player_lacks(.Grounded) && player.translation.y > collider.min.y {
		kick_collision, kick_colliding := circle_aabb_collide(kick_pos, kick_radius, collider.aabb)
		if kick_colliding {
			direction := math.sign(player.translation.x - collider.aabb.min.x)
			player.velocity.x = direction * 215
			player.facing *= -1
			player.velocity.y = jump_speed * 0.70
			player_t_add(.Kicking, 0.2)
			player_t_add(.No_Turn, 0.4)
			return
		}
	}

	// Head Collision
	if player_is(.Idle, .Running, .Skidding, .Rising, .Falling, .Riding) && player_should_collide {
		head_collision, head_collided := circle_aabb_collide(
			player.translation - {0, player.radius / 2},
			player.radius,
			collider.aabb,
		)
		if head_collided && .Oneway not_in collider.flags {
			//TODO: Head collision while riding
			if player_is(.Riding) {
			} else {
				player_resolve_level_collision(player, head_collision)
			}
		}
	}

	// Feet Collision
	if player_is(.Idle, .Running, .Skidding, .Sliding, .Crouching, .Rising, .Falling) &&
	   player_should_collide {
		feet_collision, feet_collided := circle_aabb_collide(
			player.translation + {0, player.radius / 2},
			player.radius,
			collider.aabb,
		)
		if feet_collided {
			player_resolve_level_collision(player, feet_collision)
		}
	}


	//Wall Cling Collision
	if player_is(.Falling) && player_lacks(.No_Cling) {
		cling_sensor, empty_cling_sensor := player_cling_sensors(player)
		cling_collision := circle_sensor_level_collider_overlap(
			cling_sensor.translation,
			cling_sensor.radius,
			collider,
			{.Standable, .Clingable},
		)
		empty_collision := circle_sensor_level_collider_overlap(
			empty_cling_sensor.translation,
			empty_cling_sensor.radius,
			collider,
			{.Standable, .Clingable},
		)

		if cling_collision && !empty_collision {
			new_translation: Vec2
			if player.facing == 1 {
				wall_point := collider.aabb.min
				new_translation = wall_point + {-player.radius * 2, 8}
			} else {
				wall_point := Vec2{collider.aabb.max.x, collider.aabb.min.y}
				new_translation = wall_point + {player.radius * 2, 8}
			}
			override_player_state(.Clinging)
			player.velocity = VEC_0
			player.translation = new_translation
		}
	}

	if circle_sensor_level_collider_overlap(
		player_feet_sensor,
		1,
		collider,
		{.Standable, .Oneway},
	) {
		if player_should_collide {
			on_ground^ = true
			player_remove(.Bounced)
			player_t_remove(.Just_Bounced)
			player_t_remove(.Just_Jumped)
			platform_velocity.x =
				abs(platform_velocity.x) > abs(collider.velocity.x) ? platform_velocity.x : collider.velocity.x
			platform_velocity.y =
				abs(platform_velocity.y) > abs(collider.velocity.y) ? platform_velocity.y : collider.velocity.y
		}
	}
}

ball_static_collision :: proc(collider: Collider, on_ground, in_collider: ^bool) {
	ball := &world.ball
	ball_should_collide := true


	if .Oneway in collider.flags {
		if ball.velocity.y <= 0 {
			if collider.min.y < ball.translation.y + ball.radius {
				ball_should_collide = false
			}
		}
	}
	if ball_should_collide {
		ball_ground_sensor := ball.translation + Vec2{0, ball.radius}
		ball_collision, ball_collided := circle_aabb_collide(
			ball.translation,
			ball.radius,
			collider.aabb,
		)
		if ball_collided {
			if ball_is(.Free, .Riding, .Revved) {
				ball_resolve_level_collision(ball, ball_collision)
			} else {
				in_collider^ = true
			}
		}
		
				//odinfmt: disable
			if circle_sensor_level_collider_overlap( ball_ground_sensor, 0.06, collider, {.Standable}) {
				on_ground^ = true
			}
			//odinfmt: enable
	}
}

player_ball_level_collision :: proc() {
	player := &world.player
	ball := &world.ball
	player_feet_sensor := player.translation + Vec2{0, player.radius * 1.5}
	platform_velocity: Vec2
	feet_on_ground, ball_on_ground, ball_in_collider: bool
	falling := player.velocity.y > 0

	// Concat level collision with moving blocks to test collision against a single slice of colliders
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

	// Calculate collision for the player and ball for each collider in the slice
	for collider in collision_slice {
		player_static_collision(collider, &feet_on_ground)
		ball_static_collision(collider, &ball_on_ground, &ball_in_collider)
	}

	// Update flags based on collision result
	if feet_on_ground {
		player.flags += {.Grounded, .Double_Jump}
		player.flag_timers[.Coyote] = 0.10
		player.standing_platform_velocity = {platform_velocity.x, platform_velocity.y * 0.3}
	} else {
		player.flags -= {.Grounded}
	}

	if ball_on_ground && ball_lacks(.No_Gravity) && ball_is(.Free, .Riding) {
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
	for &entity, i in assets.room_entities[world.current_room] {
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
			if !ball_is(.Recalling) {
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
		case .Checkpoint:
			bb := AABB {
				min = entity.pos,
				max = entity.pos + {8, 8},
			}
			data := &entity.data.(tags.Checkpoint_Data)
			_, player_colliding := circle_aabb_collide(player.translation, player.radius, bb)
			if player_colliding {
				world.spawn_point = Spawn_Point {
					room_tag = world.current_room,
					position = entity.pos,
				}
			}
		}
	}
}

player_ball_collision :: proc() {
	player := &world.player
	ball := &world.ball
	player_head := player.translation - {0, player.radius / 2}
	player_feet := player.translation + {0, player.radius / 2}
	if player_ball_can_interact() {
		// Calculate player hitboxes for ball interactions
		player_head := player.translation - {0, player.radius / 2}
		ball_above_head := ball.translation.y < player_head.y
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

		// Kick Hitbox
		kick_pos, kick_radius, kick_angle, is_active := player_kick_hitbox(player)

		if is_active {
			if l.distance(kick_pos, ball.translation) < kick_radius + ball.radius {
				kick_velo: Vec2
				switch kick_angle {
				case .Up:
					kick_velo = {(player.facing * 25) + player.velocity.x, -300}
				case .Forward:
					kick_velo = {(player.facing * 250) + player.velocity.x, -100}
				case .Down:
				}
				player.flag_timers[.Ignore_Ball] = 0.2
				ball.flags += {.Bounced}
				ball.velocity = kick_velo
				return
			}
		}

		ball_feet_nearest := aabb_nearest_point(player_bounce_box, ball.translation)
		feet_touching_ball := l.distance(ball_feet_nearest, ball.translation) < ball.radius

		// When sliding, send the ball up and behind and rev it
		if feet_touching_ball {
			if player_can(.Ride) {
				ride_ball()
				return
			}
			if player_has(.Grounded) {
				if player_can(.Rev_Shot) {
					log.debug("Rev Shot")
					// Rev Shot
					ball.spin = player.facing
					ball.state = .Revved
					ball.velocity = {-player.facing * 30, -175}
					ball.flags -= {.Bounced}
					player.flag_timers[.Ignore_Ball] = 0.3
					return
				}

				if math.abs(player.velocity.x) > 50 {
					ball.velocity.x = (player.facing * 150) + player.velocity.x
					return
				}


			} else {
				if player_can(.Bounce) {
					if ball_lacks(.Grounded) {
						ball.velocity.y = player.velocity.y
						ball.velocity.x *= 0.2
					}
					ball.spin = player.facing
					player.velocity.y = bounce_speed
					player.translation.y = ball.translation.y - ball.radius - (player.radius * 1.5)
					player_t_add(.Ignore_Ball, 0.1)
					player_t_add(.Just_Bounced, 0.1)
					player_add(.Bounced)
					return
				}
			}
		}
	}
}

collision_step :: proc() {
	player_ball_level_collision()
	player_ball_entity_collision()
	player_ball_transition_collision()
	player_tooltip_collision()
	player_ball_collision()
}
