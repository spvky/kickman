package main

import tags "./tags"
import "core:container/queue"
import rl "vendor:raylib"

Vec2 :: [2]f32

VEC_0 :: Vec2{0, 0}

World :: struct {
	camera:          rl.Camera2D,
	player:          Player,
	ball:            Ball,
	current_room:    tags.Room_Tag,
	event_listeners: map[Event_Type][dynamic]Event_Callback,
	event_queue:     queue.Queue(Event),
	render_mode:     Render_Mode,
}

world: World

init_world :: proc() {
	init_events_system()
	world.player.radius = 4
	world.player.translation = {18, 10}
	world.player.has_ball = true
	world.player.facing = 1
	world.player.badge_type = .Striker
	world.ball.radius = 3
	world.ball.state_flags += {.Carried}
	world.current_room = tags.Room_Tag{.tutorial, 0}
	world.render_mode = .Scaled
}

game_init :: proc() {
	rl.SetConfigFlags({.WINDOW_RESIZABLE})
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Kick man")
	init_assets()
	init_world()
}

game_update :: proc() {
	poll_input()
	physics_step()
	camera_follow_player()
	render()
	free_all(context.temp_allocator)
}
