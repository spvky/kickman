package main

import "core:container/queue"
import "core:log"
import "tags"
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
	stable_ground:   Spawn_Point,
	// Save the following fields to binary for saving/loading
	world_flags:     World_Flags,
	spawn_point:     Spawn_Point,
}

World_Flags :: struct {
	unlocks:         bit_set[Unlock_Flag;u32],
	regions_entered: bit_set[Region_Entered_Flag;u16],
}

Unlock_Flag :: enum u32 {
	Striker_Badge,
	Sisyphus_Badge,
	Spirit_Badge,
	Double_Jump,
	Lantern,
	Rubber_Toed_Boots,
}

Region_Entered_Flag :: enum u16 {
	Cave_Of_Discovery,
	Tranquil_Meadow,
	Inky_Depths,
	The_Summit,
	Will_O_Woods,
}

Game_State :: enum {
	Start_Menu,
	Pause_Menu,
	Transition,
	Gameplay,
	Map,
	Cutscene,
}

init_world :: proc() {
	init_events_system()
	world.player.radius = 4
	world.player.facing = 1
	world.player.carry_height = 16
	world.player.time_to_run_speed = 0.25
	world.player.time_to_dash_speed = 1.5
	world.ball.radius = 5
	world.current_room = tags.Room_Tag{.tutorial, 0}
	world.render_mode = .Scaled
	for entity, i in assets.room_entities[world.current_room] {
		if entity.tag == .Checkpoint {
			world.spawn_point.room_tag = world.current_room
			world.spawn_point.position = entity.pos
			break
		}
	}
	world.player.translation = world.spawn_point.position
	world.player.animation.sheet_width = f32(assets.player_texture.width)
	world.player.animation.sheet_height = f32(assets.player_texture.height)
	world.player.animation.frame_length = 1.0 / 6
	world.player.animation.sprite_width = 16
	world.player.animation.sprite_height = 20
	world.player.animation.animations = player_animations()
	summon_ball(Event{})
	init_particle_system()
	init_ball()
	subscribe_event(.Player_State_Transition, player_state_transition_listener)
}

set_room :: proc(new_room: tags.Room_Tag) {
	if new_room.region_tag != world.current_room.region_tag {
		publish_event(.Region_Change, Event_Region_Change{new_room.region_tag})
	}
	publish_event(.Room_Change, Event_Room_Change{new_room})
	world.current_room = new_room
}
