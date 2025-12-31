package level_write

import ldtk "../ldtk"
import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:time"

Binary_Collider :: struct {
	min, max: [2]int,
}

Binary_Region :: struct {
	name:       string,
	room_count: int,
	rooms:      [dynamic]Binary_Room,
}

Binary_Room :: struct {
	collision:   [dynamic]Binary_Collider,
	transitions: [dynamic]Binary_Transition,
}

Binary_Transition :: struct {
	tag:                 Room_Tag,
	transition_position: [2]f32,
	min:                 [2]f32,
	max:                 [2]f32,
}

Temp_Binary_Transition :: struct {
	// Need position
	min:               [2]int,
	max:               [2]int,
	tag:               Room_Tag,
	transition_entity: string,
	level_index:       int,
}

// Duplicating for now to avoid circular dep
Room_Tag :: struct {
	region_tag: Region_Tag,
	room_index: u8,
}

Region_Tag :: enum u8 {
	tutorial,
}
////////////////////////////////////////////

main :: proc() {
	fmt.printfln("ColliderSize %v", size_of(Binary_Collider))
	start_time := time.now()
	if project, ok := ldtk.load_from_file("../assets/levels/pell.ldtk", context.temp_allocator).?;
	   ok {
		for world in project.worlds {
			region: Binary_Region
			region.name = world.identifier
			region.room_count = len(world.levels)
			region.rooms = make([dynamic]Binary_Room, 0, 10)

			write_region_to_file(region)
			fmt.printfln("Levels Count: %v", len(world.levels))
			transitions_map := make(map[string]Temp_Binary_Transition, 16)


			for level, i in world.levels {
				room: Binary_Room
				layer_width, layer_height: int
				collision_csv: []int
				invisible_entities: []ldtk.Entity_Instance
				level_name := fmt.tprintf("%v_%02d", region.name, i)

				for layer in level.layer_instances {
					if layer.identifier == "collision_layer" {
						layer_width = layer.c_width
						layer_height = layer.c_height
						collision_csv = layer.int_grid_csv
					}
					if layer.type == .Entities {
						invisible_entities = layer.entity_instances
					}
				}
				checked: [dynamic]bool = make(
					[dynamic]bool,
					layer_height * layer_width,
					allocator = context.temp_allocator,
				)
				colliders := make([dynamic]Binary_Collider, 0, 8)
				room.transitions = make([dynamic]Binary_Transition, 0, 4)
				collider_id: int

				// Collision_Layer
				for y in 0 ..< layer_height {
					for x in 0 ..< layer_width {
						if !is_checked(checked, layer_width, x, y) {
							if check_csv_collision(collision_csv, layer_width, x, y) {
								collider_id += 1
								starting_x, starting_y := x, y
								ending_x, ending_y := x, y
								t_x, t_y := x, y
								finished_x, finished_y: bool
								for t_y <= layer_height - 1 && !finished_y {
									finished_x = false
									for t_x <= layer_width - 1 && !finished_x {
										if (t_x > ending_x || t_x == layer_width - 1) &&
										   t_y > starting_y {
											for i_x in starting_x ..= ending_x {
												// When we move to another row, mark the previous row
												mark_checked(&checked, layer_width, i_x, t_y)
											}
											break
										}
										tile_unchecked := !is_checked(
											checked,
											layer_width,
											t_x,
											t_y,
										)
										tile_collidable := check_csv_collision(
											collision_csv,
											layer_width,
											t_x,
											t_y,
										)
										if tile_unchecked && tile_collidable {
											if t_y == starting_y {
												ending_x = t_x
											}
										} else {
											if (t_x < ending_x ||
												   (t_x == ending_x && !tile_collidable)) &&
											   t_y > starting_y {
												finished_y = true
											}
											finished_x = true
										}
										// Mark initial row as we read it
										if t_y == starting_y {
											mark_checked(&checked, layer_width, t_x, t_y)
										}
										t_x += 1
									}
									if !finished_y {
										ending_y = t_y
									}
									t_x = starting_x
									t_y += 1
								}

								collider := Binary_Collider {
									min = {starting_x, starting_y},
									max = {ending_x, ending_y},
								}
								if ODIN_DEBUG {
									fmt.printfln(
										"Appending collider %v with ID %v",
										collider,
										collider_id,
									)
								}
								append(&colliders, collider)


							} else {
								// X,Y Tile is not collidable
								mark_checked(&checked, layer_width, x, y)
							}
						}
					}
				}
				fmt.printfln("%v: Colliders found %v", level_name, len(colliders))
				room.collision = colliders

				for entity in invisible_entities {
					switch entity.identifier {
					// Binary_Transition
					case "room_transition":
						transition: Temp_Binary_Transition
						transition.level_index = i
						transition.min = entity.px
						transition.max = {entity.px.x + entity.width, entity.px.y + entity.height}
						fmt.printfln("\n%v", entity.iid)
						for fi in entity.field_instances {
							if raw_value, exists := fi.value.?; exists {
								switch fi.identifier {
								case "room_index":
									room_index := u8(raw_value.(i64))
									transition.tag.room_index = room_index
								// fmt.printfln("(%v)%v: %v", fi.type, fi.identifier, fi.value)
								case "region_tag":
									region_string := raw_value.(string)
									region_tag: Region_Tag
									switch region_string {
									case "tutorial":
										region_tag = .tutorial
									}
									transition.tag.region_tag = region_tag
								// fmt.printfln("(%v)%v: %v", fi.type, fi.identifier, fi.value)
								case "other_exit":
									// TODO: Unpack the json value
									value := raw_value.(json.Object)
									entity_id := value["entityIid"].(string)
									transition.transition_entity = entity_id
								// fmt.printfln("other_exit: %v", entity_id)
								}
							}
						}
						fmt.printfln("Transitions: %v", transition)
						transitions_map[entity.iid] = transition

					// append(&region_room_transitions, transition)
					}
					//////////////////////

				}

				append(&region.rooms, room)
			}

			// Assign aabbs from entity refs
			for iid, &temp_transition in transitions_map {
				binary_transition: Binary_Transition
				if t, ok := transitions_map[temp_transition.transition_entity]; ok {
					center := (t.max + t.min) / 2
					binary_transition.transition_position = {f32(center.x), f32(center.y)}
					binary_transition.min = {
						f32(temp_transition.min.x),
						f32(temp_transition.min.y),
					}
					binary_transition.max = {
						f32(temp_transition.max.x),
						f32(temp_transition.max.y),
					}
					binary_transition.tag = temp_transition.tag
					// Append to transitions
					append(
						&region.rooms[int(temp_transition.level_index)].transitions,
						binary_transition,
					)

					// Use temp_transition.level_index to put into proper collection
				}
			}
			write_rooms_to_file(&region)
		}
		// After parsing all rooms, write the region to file in binary
	}
	free_all(context.temp_allocator)
	end_time := time.now()
	total_duration := time.duration_milliseconds(time.diff(start_time, end_time))
	fmt.printfln("Processing all rooms took %v ms", total_duration)
}

write_region_to_file :: proc(region: Binary_Region) {
	file_permissions := 0o644
	file_flags := os.O_CREATE | os.O_TRUNC | os.O_WRONLY
	dir_path := "../assets/levels/regions/"
	path := fmt.tprintf("%v%v.rgn", dir_path, region.name)
	room_count := transmute([1]u8)u8(region.room_count)
	file, err := os.open(path, file_flags, file_permissions)
	if err != nil {
		fmt.eprintln("Error opening file:", err)
	}
	defer os.close(file)
	os.write(file, room_count[:])
}

write_rooms_to_file :: proc(region: ^Binary_Region) {
	file_permissions := 0o644
	file_flags := os.O_CREATE | os.O_TRUNC | os.O_WRONLY
	collision_dir := "../assets/levels/collision/"
	invis_entities_dir := "../assets/levels/entities/"
	for room, i in region.rooms {
		level_name := fmt.tprintf("%v_%02d", region.name, i)

		// Write Collision File
		{
			collision_path := fmt.tprintf("%v%v.col", collision_dir, level_name)
			collision_file, col_err := os.open(collision_path, file_flags, file_permissions)
			if col_err != nil {
				fmt.eprintln("Error opening file:", col_err)
			}
			defer os.close(collision_file)


			collision_len := len(room.collision) * size_of(Binary_Collider)
			collision_len_bytes := transmute([8]u8)collision_len

			// Write our ints first
			n, write_err := os.write(collision_file, collision_len_bytes[:])
			if write_err != nil {
				fmt.eprintln("Error writing to file:", write_err)
			}
			// Write dynamic data
			n, write_err = os.write_ptr(collision_file, raw_data(room.collision), collision_len)
			if write_err != nil {
				fmt.eprintln("Error writing to file:", write_err)
			}
			fmt.printfln("Successfully wrote %v bytes to %v", n, collision_path)
		}
		// Write Invisible Entities File
		{
			invis_entity_path := fmt.tprintf("%v%v_invis.ent", invis_entities_dir, level_name)
			invis_entities_file, invis_err := os.open(
				invis_entity_path,
				file_flags,
				file_permissions,
			)
			if invis_err != nil {
				fmt.eprintln("Error opening file:", invis_err)
			}
			defer os.close(invis_entities_file)

			transition_len := len(room.transitions) * size_of(Binary_Transition)
			transition_len_bytes := transmute([8]u8)transition_len
			n, write_err := os.write(invis_entities_file, transition_len_bytes[:])
			if write_err != nil {
				fmt.eprintln("Error writing to file:", write_err)
			}
			//Dynamic data
			fmt.printfln("Transitions to Write: %v", room.transitions)
			n, write_err = os.write_ptr(
				invis_entities_file,
				raw_data(room.transitions),
				transition_len,
			)
			if write_err != nil {
				fmt.eprintln("Error writing to file:", write_err)
			}
			fmt.printfln("Successfully wrote %v bytes to %v", n, invis_entity_path)
		}
	}
}


check_csv_collision :: #force_inline proc(slice: []int, width, x, y: int) -> bool {
	return slice[x + (y * width)] == 1
}
is_checked :: #force_inline proc(checked: [dynamic]bool, width, x, y: int) -> bool {
	return checked[x + (y * width)]
}
mark_checked :: #force_inline proc(checked: ^[dynamic]bool, width, x, y: int) {
	checked[x + (y * width)] = true
}
