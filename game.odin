package main

import "core:log"
import rl "vendor:raylib"

Vec2 :: [2]f32

VEC_0 :: Vec2{0, 0}
VEC_X :: Vec2{1, 0}
VEC_Y :: Vec2{0, 1}

// Global Variables
world: World
assets: Assets
ui: Ui

game_init :: proc() {
	rl.SetConfigFlags({.WINDOW_RESIZABLE})
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Kick man")
	// Initialize our global variables
	init_assets()
	init_world()
	init_ui()
}

game_update :: proc() {
	delta := rl.GetFrameTime()
	pre_update(delta)
	states_update()
	dynamics_step(delta)
	flags_step(delta)
	collision_step()
	pre_render(delta)
	render()
	post_update()
	free_all(context.temp_allocator)
}


// Steps
// Pre_Update
// State_Update
// Dynamics
// Flags
// Collision
// Post_Update

game_shutdown :: proc() {
	delete_assets()
	delete_events_system()
}

states_update :: proc() {
	manage_player_state()
	handle_state_transitions()
}

pre_update :: proc(delta: f32) {
	poll_input()
	process_events()
	manage_player_juice_values(delta)
	manage_ball_juice_values(delta)
}

post_update :: proc() {
	kill_player_oob()
}

// Loop that primarily updates
pre_render :: proc(delta: f32) {
	update_entities(delta)
	update_transitions()
	update_tooltips(delta)
	camera_follow_player()
	update_particles(delta)
	update_ui(delta)
}

flags_step :: proc(delta: f32) {
	manage_player_flags(delta)
	manage_ball_flags(delta)
}
