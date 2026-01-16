package main

import "core:log"
import rl "vendor:raylib"

Vec2 :: [2]f32

VEC_0 :: Vec2{0, 0}
VEC_X :: Vec2{1, 0}
VEC_Y :: Vec2{0, 1}

game_init :: proc() {
	rl.SetConfigFlags({.WINDOW_RESIZABLE})
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Kick man")
	init_assets()
	init_world()
	init_gamepads()
}

game_update :: proc() {
	delta := rl.GetFrameTime()
	poll_input()
	physics_step(delta)
	// update_animation_player(&world.player.animation, delta)
	camera_follow_player()
	update_particles(delta)
	render()
	free_all(context.temp_allocator)
}

game_shutdown :: proc() {
	delete_assets()
	delete_events_system()
}
