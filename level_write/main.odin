package level_write

import ldtk "../ldtk"
import "core:fmt"
import "core:os"
import "core:time"

Binary_Collider :: struct {
	min, max: [2]int,
}

Binary_Region :: struct {
	name:  string,
	rooms: [dynamic]Binary_Room,
}

Binary_Room :: struct {
	// Id field should go here to handle
	collision:  [dynamic]Binary_Collider,
	width:      int,
	height:     int,
	image_path: string,
}

main :: proc() {
	fmt.printfln("ColliderSize %v", size_of(Binary_Collider))
	start_time := time.now()
	if project, ok := ldtk.load_from_file("../assets/levels/pell.ldtk", context.temp_allocator).?;
	   ok {
		for world in project.worlds {
			region: Binary_Region
			region.name = world.identifier
			region.rooms = make([dynamic]Binary_Room, 0, 10)

			fmt.printfln("Levels Count: %v", len(world.levels))

			for level, i in world.levels {
				room: Binary_Room
				room.image_path = fmt.tprintf("assets/levels/pell/png/%v-collision_layer.png", i)
				layer_width, layer_height: int
				collision_csv: []int
				for layer in level.layer_instances {
					if layer.identifier == "collision_layer" {
						layer_width = layer.c_width
						layer_height = layer.c_height
						room.height = layer_height
						room.width = layer_width
						collision_csv = layer.int_grid_csv
					}
				}
				fmt.printfln("Int Grid length: %v", len(collision_csv))
				checked: [dynamic]bool = make(
					[dynamic]bool,
					layer_height * layer_width,
					allocator = context.temp_allocator,
				)
				colliders := make([dynamic]Binary_Collider, 0, 8)
				collider_id: int

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
										if t_x > ending_x && t_y > starting_y do break
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
											if t_x < ending_x && t_y > starting_y {
												finished_y = true
											}
											finished_x = true
										}
										mark_checked(&checked, layer_width, t_x, t_y)
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
								fmt.printfln(
									"Appending collider %v with ID %v",
									collider,
									collider_id,
								)
								append(&colliders, collider)


							} else {
								// X,Y Tile is not collidable
								mark_checked(&checked, layer_width, x, y)
							}
						}
					}
				}
				fmt.printfln("Colliders found %v", len(colliders))
				room.collision = colliders
				append(&region.rooms, room)
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

write_rooms_to_file :: proc(region: ^Binary_Region) {
	file_permissions := 0o644
	file_flags := os.O_CREATE | os.O_TRUNC | os.O_WRONLY
	dir_path := "../assets/levels/bin/"
	for room, i in region.rooms {
		level_name := fmt.tprintf("%v_%02d", region.name, i)
		path := fmt.tprintf("%v%v.lvl", dir_path, level_name)
		file, err := os.open(path, file_flags, file_permissions)
		if err != nil {
			fmt.eprintln("Error opening file:", err)
		}
		defer os.close(file)

		// Write level name and it's length to the file
		// name := transmute([]u8)level_name
		// name_len := transmute([8]u8)len(name)
		// os.write(file, name_len[:])
		// os.write(file, name)

		// // Write the path to the levels png and its len
		image_path := transmute([]u8)room.image_path
		image_path_len := transmute([8]u8)len(image_path)
		width_array := transmute([8]u8)room.width
		height_array := transmute([8]u8)room.height
		fmt.printfln("Collider Count %v", len(room.collision))
		collision_len := len(room.collision) * size_of(Binary_Collider)
		collision_len_bytes := transmute([8]u8)collision_len

		// Write our ints first
		os.write(file, image_path_len[:])
		os.write(file, width_array[:])
		os.write(file, height_array[:])
		os.write(file, collision_len_bytes[:])
		// Write dynamic data
		os.write(file, image_path)
		n, write_err := os.write_ptr(file, raw_data(room.collision), collision_len)
		if write_err != nil {
			fmt.eprintln("Error writing to file:", write_err)
		}
		fmt.printfln("Successfully wrote %v bytes to %v", n, path)
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
