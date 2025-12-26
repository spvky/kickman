package level_read

import lvl_write "../level_write"
import "core:fmt"
import "core:os"

main :: proc() {
	room, ok := read_room_from_file("../assets/levels/bin/tutorial_00.lvl")
	if ok {
		fmt.printfln("%v", room)
	}
}

read_room_from_file :: proc(filename: string) -> (room: lvl_write.Binary_Room, success: bool) {
	file, read_err := os.open(filename)
	if read_err != nil {
		fmt.eprintfln("Failed to read %v: %v", filename, read_err)
		return
	}

	bytes_read: int
	image_path_len, collision_len: int

	// read room name
	// bytes_read, read_err = os.read_ptr(file, &name_len, size_of(int))
	// if read_err != nil {
	// 	fmt.eprintfln("Failed to read %v: %v", filename, read_err)
	// 	return
	// }
	// bytes_read, read_err = os.read_ptr(file, &room.name, name_len)
	// if read_err != nil {
	// 	fmt.eprintfln("Failed to read %v: %v", filename, read_err)
	// 	return
	// }


	// Read room image_path
	bytes_read, read_err = os.read_ptr(file, &image_path_len, size_of(int))
	if read_err != nil {
		fmt.eprintfln("Failed to read %v: %v", filename, read_err)
		return
	}
	bytes_read, read_err = os.read_ptr(file, &room.image_path, image_path_len)
	if read_err != nil {
		fmt.eprintfln("Failed to read %v: %v", filename, read_err)
		return
	}

	// Read room width and height
	bytes_read, read_err = os.read_ptr(file, &room.width, size_of(int))
	if read_err != nil {
		fmt.eprintfln("Failed to read %v: %v", filename, read_err)
		return
	}
	bytes_read, read_err = os.read_ptr(file, &room.height, size_of(int))
	if read_err != nil {
		fmt.eprintfln("Failed to read %v: %v", filename, read_err)
		return
	}

	bytes_read, read_err = os.read_ptr(file, &collision_len, size_of(int))
	if read_err != nil {
		fmt.eprintfln("Failed to read %v: %v", filename, read_err)
		return
	}
	room.room_collision = make([dynamic]lvl_write.Binary_Collider, 0, collision_len)

	bytes_read, read_err = os.read_ptr(file, &room.room_collision, collision_len)
	if read_err != nil {
		fmt.eprintfln("Failed to read %v: %v", filename, read_err)
		return
	}

	success = true
	return
}
