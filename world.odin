package main

import tags "./tags"
import "core:container/queue"
import "core:log"
import rl "vendor:raylib"

World :: struct {
	camera:          rl.Camera2D,
	player:          Player,
	ball:            Ball,
	spawn_point:     Spawn_Point,
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
	for entity, i in assets.room_entities[world.current_room] {
		log.debugf("Entity %v", entity.tag)
		if entity.tag == .Checkpoint {
			log.debugf("Found Checkpoint %v", entity.pos)
			checkpoint_pos = entity.pos
			world.spawn_point.room_tag = world.current_room
			world.spawn_point.entity_index = i
			break
		}
	}
	world.player.translation = checkpoint_pos
	init_particle_system()
	subscribe_event(.Player_State_Transition, player_state_transition_listener)
}
