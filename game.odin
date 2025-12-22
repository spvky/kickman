package main

import "core:container/queue"
import "core:fmt"
import rl "vendor:raylib"

Vec2 :: [2]f32

World :: struct {
	camera:          rl.Camera2D,
	player:          Player,
	ball:            Ball,
	level_collision: [dynamic]Level_Collider,
	event_listeners: map[Event_Type][dynamic]Event_Callback,
	event_queue:     queue.Queue(Event),
}

world: World

init_world :: proc() {
	init_events_system()
	world.player.radius = 8
	world.player.translation = {200, 125}
	world.ball.radius = 4
	world.ball.carried = true
	world.level_collision = make([dynamic]Level_Collider, 0, 16)
	build_level()
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
	render()
}
