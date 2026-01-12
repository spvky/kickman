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
	particles:       Particle_System,
}

world: World

init_world :: proc() {
	init_events_system()
	world.player.radius = 4
	world.player.translation = {18, 10}
	world.player.flags += {.Has_Ball}
	world.player.facing = 1
	world.player.badge_type = .Striker
	world.player.time_to_run_speed = 0.25
	world.player.time_to_dash_speed = 1.5
	world.ball.radius = 3
	world.ball.state = .Carried
	world.current_room = tags.Room_Tag{.tutorial, 0}
	world.render_mode = .Scaled
	checkpoint_pos: Vec2
	for entity in assets.room_entities[world.current_room] {
		if entity.tag == .Checkpoint {
			checkpoint_pos = entity.pos
			//TODO: set spawn point here
		}
	}
	init_particle_system()
	subscribe_event(.Player_State_Transition, player_state_transition_listener)
}
