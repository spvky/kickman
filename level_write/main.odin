package level_write

import ldtk "../ldtk"
import tags "../tags"
import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:time"

Binary_Collider :: struct {
	min, max: [2]int,
	flags:    bit_set[tags.Collider_Flag;u8],
}

Binary_Region :: struct {
	name:       string,
	room_count: int,
	rooms:      [dynamic]Binary_Room,
}

Binary_Room :: struct {
	collision:   [dynamic]Binary_Collider,
	transitions: [dynamic]Binary_Transition,
	entities:    [dynamic]tags.Entity,
	tooltips:    [dynamic]tags.Tooltip,
}

Binary_Transition :: struct {
	tag:                 tags.Room_Tag,
	transition_position: [2]f32,
	min:                 [2]f32,
	max:                 [2]f32,
}

Temp_Entity :: struct {
	id:   string,
	tag:  tags.Entity_Tag,
	pos:  [2]int,
	data: Temp_Entity_Data,
}

Temp_Entity_Data :: union {
	Temp_Movable_Block_Data,
	Temp_Tooltip_Data,
}

Temp_Movable_Block_Data :: struct {
	trigger_ref: string,
	points:      [2][2]int,
	extents:     [2]int,
	speed:       f32,
}

Temp_Tooltip_Data :: struct {
	message:       string,
	display_point: [2]int,
	extents:       [2]int,
}

Temp_Binary_Transition :: struct {
	min:               [2]int,
	max:               [2]int,
	tag:               tags.Room_Tag,
	transition_entity: string,
	level_index:       int,
}

main :: proc() {
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
				entities: []ldtk.Entity_Instance
				transition_entities: []ldtk.Entity_Instance
				level_name := fmt.tprintf("%v_%02d", region.name, i)
				temp_entities_array := make([dynamic]Temp_Entity, 0, 32)
				tooltips_array := make([dynamic]tags.Tooltip, 0, 4)

				for layer in level.layer_instances {
					if layer.identifier == "collision_layer" {
						layer_width = layer.c_width
						layer_height = layer.c_height
						collision_csv = layer.int_grid_csv
					}
					if layer.identifier == "transitions" {
						transition_entities = layer.entity_instances
					}
					if layer.identifier == "entities" {
						entities = layer.entity_instances
					}
				}
				checked: [dynamic]bool = make(
					[dynamic]bool,
					layer_height * layer_width,
					allocator = context.temp_allocator,
				)
				colliders := make([dynamic]Binary_Collider, 0, 8)
				room.transitions = make([dynamic]Binary_Transition, 0, len(transition_entities))
				collider_id: int

				// Collision_Layer
				for y in 0 ..< layer_height {
					for x in 0 ..< layer_width {
						if !is_checked(checked, layer_width, x, y) {
							collision_type_value := get_csv_collision_value(
								collision_csv,
								layer_width,
								x,
								y,
							)
							if collision_type_value == 0 {
								mark_checked(&checked, layer_width, x, y)
								continue
							}
							if check_csv_collision(
								collision_type_value,
								collision_csv,
								layer_width,
								x,
								y,
							) {
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
											collision_type_value,
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
											if get_csv_collision_value(
												   collision_csv,
												   layer_width,
												   t_x,
												   t_y,
											   ) ==
											   collision_type_value {

												mark_checked(&checked, layer_width, t_x, t_y)
											}
										}
										t_x += 1
									}
									if !finished_y {
										ending_y = t_y
									}
									t_x = starting_x
									t_y += 1
								}

								flags: bit_set[tags.Collider_Flag;u8]
								switch collision_type_value {
								case 1:
									flags += {.Standable}
								case 2:
									flags += {.Standable, .Oneway}
								}

								collider := Binary_Collider {
									min   = {starting_x, starting_y},
									max   = {ending_x, ending_y},
									flags = flags,
								}
								if ODIN_DEBUG {
									fmt.printfln(
										"Appending collider %v with ID %v",
										collider,
										collider_id,
									)
								}
								append(&colliders, collider)
							}
						}
					}
				}
				fmt.printfln("%v: Colliders found %v", level_name, len(colliders))
				room.collision = colliders

				for entity in transition_entities {
					switch entity.identifier {
					case "room_transition":
						transition: Temp_Binary_Transition
						transition.level_index = i
						transition.min = entity.px
						transition.max = {entity.px.x + entity.width, entity.px.y + entity.height}
						for fi in entity.field_instances {
							if raw_value, exists := fi.value.?; exists {
								switch fi.identifier {
								case "room_index":
									room_index := u8(raw_value.(i64))
									transition.tag.room_index = room_index
								case "region_tag":
									region_string := raw_value.(string)
									region_tag: tags.Region_Tag
									switch region_string {
									case "tutorial":
										region_tag = .tutorial
									}
									transition.tag.region_tag = region_tag
								case "other_exit":
									value := raw_value.(json.Object)
									entity_id := value["entityIid"].(string)
									transition.transition_entity = entity_id
								// fmt.printfln("other_exit: %v", entity_id)
								}
							}
						}
						transitions_map[entity.iid] = transition
					}
				}

				for entity in entities {
					switch entity.identifier {
					// Binary_Transition
					case "lever":
						temp_entity: Temp_Entity
						temp_entity.tag = .Lever
						temp_entity.pos = entity.px
						temp_entity.id = entity.iid
						append(&temp_entities_array, temp_entity)
					case "button":
						temp_entity: Temp_Entity
						temp_entity.tag = .Button
						temp_entity.pos = entity.px
						temp_entity.id = entity.iid
						append(&temp_entities_array, temp_entity)
					case "checkpoint":
						fmt.printfln("Found a checkpoint")
						temp_entity: Temp_Entity
						temp_entity.tag = .Checkpoint
						temp_entity.pos = entity.px
						append(&temp_entities_array, temp_entity)
					case "movable_block":
						temp_entity: Temp_Entity
						temp_entity.tag = .Movable_Block
						temp_entity.pos = entity.px
						entity_data := Temp_Movable_Block_Data {
							extents = {entity.width, entity.height},
						}
						for fi in entity.field_instances {
							if raw_value, exists := fi.value.?; exists {
								switch fi.identifier {
								case "trigger":
									value := raw_value.(json.Object)
									entity_id := value["entityIid"].(string)
									entity_data.trigger_ref = entity_id
								case "positions":
									value := raw_value.(json.Array)
									p1 := value[0].(json.Object)
									p2 := value[1].(json.Object)

									entity_data.points[0] = [2]int {
										int(p1["cx"].(i64)),
										int(p1["cy"].(i64)),
									}
									entity_data.points[1] = [2]int {
										int(p2["cx"].(i64)),
										int(p2["cy"].(i64)),
									}
								case "speed":
									speed := f32(raw_value.(f64))
									entity_data.speed = speed
								}
							}
						}
						temp_entity.data = entity_data
						temp_entity.id = entity.iid
						append(&temp_entities_array, temp_entity)
					case "tooltip":
						tooltip: tags.Tooltip
						tooltip.pos = [2]f32{f32(entity.px.x), f32(entity.px.y)}
						tooltip.extents = {f32(entity.width), f32(entity.height)}
						for fi in entity.field_instances {
							if raw_value, exists := fi.value.?; exists {
								switch fi.identifier {
								case "message":
									value := raw_value.(json.String)
									tooltip.message = value
								case "display_point":
									dp := raw_value.(json.Object)
									tooltip.display_point = [2]f32 {
										f32(int(dp["cx"].(i64))) * 4,
										f32(int(dp["cy"].(i64))) * 4,
									}
								}
							}
						}
						append(&tooltips_array, tooltip)
					}
				}
				room.tooltips = tooltips_array

				entities_array := make([dynamic]tags.Entity, 0, len(temp_entities_array))

				fmt.printfln("Temp Entities Found: %v", len(temp_entities_array))
				for te in temp_entities_array {
					new_entity: tags.Entity
					new_entity.pos = [2]f32{f32(te.pos.x), f32(te.pos.y)}
					new_entity.tag = te.tag
					switch te.tag {
					case .Movable_Block:
						//
						data: tags.Movable_Block_Data
						temp_data := te.data.(Temp_Movable_Block_Data)
						data.extents = [2]f32{f32(temp_data.extents.x), f32(temp_data.extents.y)}
						for p, i in temp_data.points {
							data.positions[i] = [2]f32{f32(p.x * 4), f32(p.y * 4)}
						}
						for tte, i in temp_entities_array {
							if tte.id == temp_data.trigger_ref {
								data.trigger_index = i
							}
						}
						data.speed = temp_data.speed
						new_entity.data = data
					case .Lever, .Button, .Checkpoint:
						new_entity.data = tags.Trigger_Data {
							on = false,
						}
					}
					append(&entities_array, new_entity)
				}

				room.entities = entities_array
				append(&region.rooms, room)
			}

			// Assign aabbs and transition points from entity refs
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
	entities_dir := "../assets/levels/entities/"
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
		// Write Transitions File
		{
			transition_path := fmt.tprintf("%v%v.trns", entities_dir, level_name)
			transition_file, trns_err := os.open(transition_path, file_flags, file_permissions)
			if trns_err != nil {
				fmt.eprintln("Error opening file:", trns_err)
			}
			defer os.close(transition_file)

			transition_len := len(room.transitions) * size_of(Binary_Transition)
			transition_len_bytes := transmute([8]u8)transition_len
			n, write_err := os.write(transition_file, transition_len_bytes[:])
			if write_err != nil {
				fmt.eprintln("Error writing to file:", write_err)
			}
			//Dynamic data
			n, write_err = os.write_ptr(
				transition_file,
				raw_data(room.transitions),
				transition_len,
			)
			if write_err != nil {
				fmt.eprintln("Error writing to file:", write_err)
			}
			fmt.printfln("Successfully wrote %v bytes to %v", n, transition_path)
		}
		// Write Entity File
		{
			entity_path := fmt.tprintf("%v%v.ent", entities_dir, level_name)
			entity_file, ent_err := os.open(entity_path, file_flags, file_permissions)
			if ent_err != nil {
				fmt.eprintln("Error opening file:", ent_err)
			}
			defer os.close(entity_file)

			entity_len := len(room.entities) * size_of(tags.Entity)
			entity_len_bytes := transmute([8]u8)entity_len
			n, write_err := os.write(entity_file, entity_len_bytes[:])
			if write_err != nil {
				fmt.eprintln("Error writing to file:", write_err)
			}
			//Dynamic data
			fmt.printfln("Entities to Write: %v", room.entities)
			n, write_err = os.write_ptr(entity_file, raw_data(room.entities), entity_len)
			if write_err != nil {
				fmt.eprintln("Error writing to file:", write_err)
			}

			tooltip_path := fmt.tprintf("%v%v.tt", entities_dir, level_name)
			tooltip_file, tool_err := os.open(tooltip_path, file_flags, file_permissions)
			if tool_err != nil {
				fmt.eprintln("Error opening file:", tool_err)
			}
			defer os.close(tooltip_file)
			n = write_tooltips_to_file(room.tooltips, tooltip_file)
			fmt.printfln("Successfully wrote %v bytes to %v", n, tooltip_path)
		}
	}
}

write_tooltips_to_file :: proc(
	tooltips: [dynamic]tags.Tooltip,
	file: os.Handle,
) -> (
	bytes_written: int,
) {
	// Tooltips (use strings so writing will be slightly more complicated)
	tooltips_len := len(tooltips)
	tooltips_len_bytes := transmute([8]u8)tooltips_len
	n, write_err := os.write(file, tooltips_len_bytes[:])
	bytes_written += n
	for tt in tooltips {
		bytes_written += write_string_to_file(file, tt.message)
		bytes_written += write_fixed_to_file(file, tt.pos)
		bytes_written += write_fixed_to_file(file, tt.display_point)
		bytes_written += write_fixed_to_file(file, tt.extents)
		//Skip writing the last 5 bytes, as they are all zero
	}
	return
}

write_fixed_to_file :: #force_inline proc(file: os.Handle, value: $T) -> (bytes_read: int) {
	val_bytes := transmute([size_of(T)]u8)value
	n, write_err := os.write(file, val_bytes[:])
	if write_err != nil {
	}
	bytes_read = n
	return
}

write_string_to_file :: #force_inline proc(
	file: os.Handle,
	value: string,
) -> (
	bytes_written: int,
) {
	str_len := len(value)
	bytes_written += write_fixed_to_file(file, str_len)
	n, write_err := os.write_ptr(file, raw_data(value), str_len)
	bytes_written += n
	return
}


check_csv_collision :: #force_inline proc(
	collision_type: int,
	slice: []int,
	width, x, y: int,
) -> bool {
	return slice[x + (y * width)] == collision_type
}
get_csv_collision_value :: #force_inline proc(slice: []int, width, x, y: int) -> int {
	return slice[x + (y * width)]
}
is_checked :: #force_inline proc(checked: [dynamic]bool, width, x, y: int) -> bool {
	return checked[x + (y * width)]
}
mark_checked :: #force_inline proc(checked: ^[dynamic]bool, width, x, y: int) {
	checked[x + (y * width)] = true
}
