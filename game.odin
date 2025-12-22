package main

import "core:fmt"
import rl "vendor:raylib"

Vec2 :: [2]f32

Rigidbody :: struct {
	translation: Vec2,
	velocity:    Vec2,
	radius:      f32,
}

World :: struct {
	camera:          rl.Camera2D,
	player:          Player,
	ball:            Ball,
	level_collision: [dynamic]Level_Collider,
}

world: World

init_world :: proc() {
	world.player.radius = 8
	world.player.translation = {200, 125}
	world.ball.radius = 4
	world.level_collision = make([dynamic]Level_Collider, 0, 16)
}

game_init :: proc() {
	rl.SetConfigFlags({.WINDOW_RESIZABLE})
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Kick man")
	init_assets()
	init_world()
}

game_update :: proc() {
	render()
}
