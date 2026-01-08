package main

import lr "./level_read"
import lw "./level_write"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:time"
import tags "tags"
import rl "vendor:raylib"

WINDOW_WIDTH: i32 = 1920
WINDOW_HEIGHT: i32 = 1080
SCREEN_WIDTH :: 400 //25x14 16 pixel tiles
SCREEN_HEIGHT :: 224

Assets :: struct {
	gameplay_texture: rl.RenderTexture,
	raw_atlas:        rl.Texture2D,
	room_textures:    map[tags.Room_Tag]rl.Texture2D,
	room_dimensions:  map[tags.Room_Tag]Vec2,
	room_collision:   map[tags.Room_Tag][dynamic]Collider,
	room_transitions: map[tags.Room_Tag][dynamic]Room_Transition,
	room_entities:    map[tags.Room_Tag][dynamic]tags.Entity,
}

assets: Assets

init_assets :: proc() {
	assets.gameplay_texture = rl.LoadRenderTexture(WINDOW_WIDTH, WINDOW_HEIGHT)
	assets.raw_atlas = rl.LoadTexture("assets/cave_tiles.png")
	assets.room_dimensions = make(map[tags.Room_Tag]Vec2, 10)
	assets.room_textures = make(map[tags.Room_Tag]rl.Texture2D, 10)
	assets.room_collision = make(map[tags.Room_Tag][dynamic]Collider, 10)
	assets.room_transitions = make(map[tags.Room_Tag][dynamic]Room_Transition, 10)
	assets.room_entities = make(map[tags.Room_Tag][dynamic]tags.Entity, 10)
	load_region_data(.tutorial)
}

delete_assets :: proc() {
	rl.UnloadRenderTexture(assets.gameplay_texture)
	rl.UnloadTexture(assets.raw_atlas)
	delete(assets.room_dimensions)
	for _, v in assets.room_textures {
		rl.UnloadTexture(v)
	}
	for _, v in assets.room_collision {
		delete(v)
	}
	for _, v in assets.room_transitions {
		delete(v)
	}
	for _, v in assets.room_entities {
		delete(v)
	}
	delete(assets.room_textures)
	delete(assets.room_collision)
	delete(assets.room_transitions)
	delete(assets.room_entities)
}

load_region_data :: proc(tag: tags.Region_Tag) {
	start_time := time.now()
	filename := fmt.tprintf("assets/levels/regions/%v.rgn", tag)
	file, read_err := os.open(filename)
	if read_err != nil {
		fmt.eprintfln("Failed to read %v: %v", filename, read_err)
		return
	}

	room_count: int

	bytes_read, err := os.read_ptr(file, &room_count, size_of(int))
	if err != nil {
		fmt.printfln("Failed to read %v: %v", filename, err)
	}
	for i in 0 ..< room_count {
		room_tag := tags.Room_Tag {
			region_tag = tag,
			room_index = u8(i),
		}
		// Textures
		texture_path := fmt.tprintf(
			"assets/levels/pell/png/%v_%v-collision_layer.png",
			tag,
			room_tag.room_index,
		)
		texture := rl.LoadTexture(
			strings.clone_to_cstring(texture_path, allocator = context.temp_allocator),
		)
		// Collision
		collision_path := fmt.tprintf(
			"assets/levels/collision/%v_%02d.col",
			tag,
			room_tag.room_index,
		)
		collision_binary, ok := lr.read_room_collision_from_file(collision_path)
		if !ok {
			fmt.printfln("Failed to read collision for %v", collision_path)
			return
		}

		collision := make([dynamic]Collider, 0, len(collision_binary.collision))

		for c in collision_binary.collision {
			collider: Collider
			collider.min = {f32(c.min.x) * TILE_SIZE, f32(c.min.y) * TILE_SIZE}
			collider.max = {f32(c.max.x + 1) * TILE_SIZE, f32(c.max.y + 1) * TILE_SIZE}
			collider.flags = c.flags
			append(&collision, collider)
		}


		// Room Transitions
		transition_path := fmt.tprintf(
			"assets/levels/entities/%v_%02d.trns",
			tag,
			room_tag.room_index,
		)
		transition_binary, transition_ok := lr.read_room_transitions_from_file(transition_path)
		if !transition_ok {
			fmt.printfln("Failed to read transitions for %v", transition_path)
			return
		}
		transitions := make([dynamic]Room_Transition, 0, len(transition_binary.transitions))

		for t in transition_binary.transitions {
			transition: Room_Transition
			//TODO: move types to shared module
			transition.tag.region_tag = .tutorial
			transition.tag.room_index = t.tag.room_index
			transition.transition_position = t.transition_position
			transition.min = t.min
			transition.max = t.max
			append(&transitions, transition)
		}

		// Entities
		entity_path := fmt.tprintf("assets/levels/entities/%v_%02d.ent", tag, room_tag.room_index)
		entity_binary, entity_ok := lr.read_room_entities_from_file(entity_path)
		if !transition_ok {
			fmt.printfln("Failed to read entities for %v", entity_path)
			return
		}
		entities := make([dynamic]tags.Entity, 0, len(entity_binary.entities))

		for e in entity_binary.entities {
			// Still keeping the loop here in case there is data that needs to be instantiated at runtime
			append(&entities, e)
		}

		assets.room_dimensions[room_tag] = Vec2{f32(texture.width), f32(texture.height)}
		assets.room_textures[room_tag] = texture
		assets.room_collision[room_tag] = collision
		assets.room_transitions[room_tag] = transitions
		assets.room_entities[room_tag] = entities
		fmt.printfln("%v", assets.room_entities[room_tag])
	}
	end_time := time.now()
	total_duration := time.duration_milliseconds(time.diff(start_time, end_time))
	fmt.printfln("Loading region %v took %v ms", tag, total_duration)
}
