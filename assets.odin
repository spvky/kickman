package main

import lr "./level_read"
import lw "./level_write"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:time"
import rl "vendor:raylib"

WINDOW_WIDTH: i32 = 1920
WINDOW_HEIGHT: i32 = 1080
SCREEN_WIDTH :: 400 //25x14 16 pixel tiles
SCREEN_HEIGHT :: 224

Assets :: struct {
	gameplay_texture: rl.RenderTexture,
	room_textures:    map[Room_Tag]rl.Texture2D,
	room_collision:   map[Room_Tag]Room_Collision,
}

assets: Assets

init_assets :: proc() {
	assets.gameplay_texture = rl.LoadRenderTexture(WINDOW_WIDTH, WINDOW_HEIGHT)
	assets.room_textures = make(map[Room_Tag]rl.Texture2D, 10)
	assets.room_collision = make(map[Room_Tag]Room_Collision, 10)
	load_region_data(.tutorial)
}

load_region_data :: proc(tag: Region_Tag) {
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
		room_tag := Room_Tag {
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

		collision := make([dynamic]Level_Collider, 0, len(collision_binary.collision))

		for c in collision_binary.collision {
			collider: Level_Collider
			collider.min = {f32(c.min.x) * TILE_SIZE, f32(c.min.y) * TILE_SIZE}
			collider.max = {f32(c.max.x + 1) * TILE_SIZE, f32(c.max.y + 1) * TILE_SIZE}
			collider.flags = {.Standable}
			append(&collision, collider)
		}

		assets.room_textures[room_tag] = texture
		assets.room_collision[room_tag] = {
			room_collision = collision,
		}
	}
	end_time := time.now()
	total_duration := time.duration_milliseconds(time.diff(start_time, end_time))
	fmt.printfln("Loading region %v took %v ms", tag, total_duration)
}

// TODO: Load collision
