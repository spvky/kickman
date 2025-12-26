package level_read

import lvl_write "../level_write"
import "core:fmt"
import "core:os"
import "core:slice"
import "core:time"

main :: proc() {
	start_time := time.now()
	room, ok := read_room_from_file("../assets/levels/bin/tutorial_00.lvl")
	if ok {
		fmt.printfln("%v", len(room.collision))
	}
	end_time := time.now()
	total_duration := time.duration_milliseconds(time.diff(start_time, end_time))
	fmt.printfln("Reading room took %v ms", total_duration)
}

read_room_from_file :: proc(filename: string) -> (room: lvl_write.Binary_Room, success: bool) {
	file, read_err := os.open(filename)
	if read_err != nil {
		fmt.eprintfln("Failed to read %v: %v", filename, read_err)
		return
	}

	bytes_read: int
	image_path_len, collision_len, height, width: int
	image_path: string

	// Read ints from the start of the file
	bytes_read = read_int_from_file(file, &image_path_len)
	bytes_read = read_int_from_file(file, &width)
	bytes_read = read_int_from_file(file, &height)
	bytes_read = read_int_from_file(file, &collision_len)
	// Read dynamic data from the file
	bytes_read = read_string_from_file(file, &image_path, image_path_len)
	collision_raw := make(
		[]lvl_write.Binary_Collider,
		collision_len / size_of(lvl_write.Binary_Collider),
	)
	collision_bytes := slice.to_bytes(collision_raw)
	bytes_read, read_err = os.read_full(file, collision_bytes)
	if read_err != nil {
		fmt.printfln("Failed to read %v: %v", filename, read_err)
		return
	}
	colliders := slice.clone_to_dynamic(collision_raw)

	if ODIN_DEBUG {
		fmt.printfln("Image Path len %v", image_path_len)
		fmt.printfln("Width %v", width)
		fmt.printfln("Height %v", height)
		fmt.printfln("Collision Len %v", collision_len)
		fmt.printfln("Image Path %v", image_path)
		fmt.printfln("Collision dynamic len %v", len(colliders))
	}
	room.image_path = image_path
	room.width = width
	room.height = height
	room.collision = colliders


	success = true
	return
}

// Read int from passed file into the passed pointer
read_int_from_file :: proc(file: os.Handle, destination: ^int) -> (bytes_read: int) {
	n, err := os.read_ptr(file, destination, size_of(int))
	bytes_read = n
	if err != nil {
		fmt.printfln("Failed to read %v", err)
	}
	return
}

// Reads string from passed file into pointer, given length, allocates using context.allocator
read_string_from_file :: proc(
	file: os.Handle,
	destination: ^string,
	len: int,
) -> (
	bytes_read: int,
) {
	value_bytes := make([]u8, len)
	n, read_err := os.read_full(file, value_bytes)
	bytes_read = n
	if read_err != nil {
		fmt.printfln("Failed to read %v", read_err)
		return
	}
	destination^ = string(value_bytes)
	return
}
