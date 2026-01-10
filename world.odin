package main

import tags "./tags"
import "core:container/queue"
import rl "vendor:raylib"

World :: struct {
	camera:          rl.Camera2D,
	player:          Player,
	ball:            Ball,
	current_room:    tags.Room_Tag,
	event_listeners: map[Event_Type][dynamic]Event_Callback,
	event_queue:     queue.Queue(Event),
	render_mode:     Render_Mode,
	dust_particles:  Particle_Emitter(100),
}

world: World

init_world :: proc() {
	init_events_system()
	world.player.radius = 4
	world.player.translation = {18, 10}
	world.player.flags += {.Has_Ball}
	world.player.facing = 1
	world.player.badge_type = .Striker
	world.player.time_to_top_speed = 0.25
	world.ball.radius = 3
	world.ball.state = .Carried
	world.current_room = tags.Room_Tag{.tutorial, 0}
	world.render_mode = .Scaled

	world.dust_particles = Particle_Emitter(100) {
		color    = {255, 255, 255, 100},
		gravity  = {0, 200},
		display  = Particle_Emitter_Circle{0.5, 1.5},
		lifetime = 0.5,
		effects  = {.Fade},
	}

	subscribe_event(.Player_State_Transition, player_state_transition_listener)
}
