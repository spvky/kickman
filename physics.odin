package main

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

apply_player_ball_velocity :: proc(delta: f32) {
	world.player.translation += world.player.velocity * delta
	if !world.ball.carried {
		world.ball.translation += world.ball.velocity * delta
	}
}

physics_step :: proc() {
	delta := rl.GetFrameTime()
	player_jump()
	apply_player_ball_gravity(delta)
	apply_player_ball_velocity(delta)
	player_ball_level_collision()
}
