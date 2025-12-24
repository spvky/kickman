package converter

import game ".."
import ldtk "../ldtk"
import "core:fmt"

Temp_Collider :: struct {
	min, max: [2]int,
}


main :: proc() {
	if project, ok := ldtk.load_from_file("../assets/levels/pell.ldtk", context.temp_allocator).?;
	   ok {
		for world in project.worlds {
			region: game.Region
			region.name = world.identifier
			region.rooms = make([dynamic]game.Room, 0, 10)

			fmt.printfln("Levels Count: %v", len(world.levels))

			for level in world.levels {
				layer_width, layer_height: int
				collision_csv: []int
				for layer in level.layer_instances {
					if layer.identifier == "collision_layer" {
						layer_width = layer.c_width
						layer_height = layer.c_height
						collision_csv = layer.int_grid_csv
					}
				}
				fmt.printfln("Int Grid length: %v", len(collision_csv))
				checked: [dynamic]bool = make(
					[dynamic]bool,
					layer_height * layer_width,
					allocator = context.temp_allocator,
				)
				colliders := make([dynamic]Temp_Collider, 0, 8)
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

								collider := Temp_Collider {
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
				// End reading grid
			}
		}
	}
	free_all(context.temp_allocator)
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
