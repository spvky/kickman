package level_read

import lvl_write "../level_write"
import tags "../tags"
import "core:fmt"
import "core:os"
import "core:slice"
import "core:time"

main :: proc() {
	start_time := time.now()
	room, ok := read_room_collision_from_file("../assets/levels/collision/tutorial_00.col")
	if ok {
		fmt.printfln("%v", len(room.collision))
	}
	end_time := time.now()
	total_duration := time.duration_milliseconds(time.diff(start_time, end_time))
	fmt.printfln("Reading room took %v ms", total_duration)
}

load_region :: proc(path: string) {
	file, read_err := os.open(path)
	if read_err != nil {

	}
}

read_room_collision_from_file :: proc(
	filename: string,
) -> (
	room: lvl_write.Binary_Room,
	success: bool,
) {
	file, read_err := os.open(filename)
	if read_err != nil {
		fmt.eprintfln("Failed to read %v: %v", filename, read_err)
		return
	}
	defer os.close(file)

	bytes_read: int
	collision_len: int

	// Read ints from the start of the file
	bytes_read = read_int_from_file(file, &collision_len)
	// Read dynamic data from the file
	collision_raw := make(
		[]lvl_write.Binary_Collider,
		collision_len / size_of(lvl_write.Binary_Collider),
		allocator = context.temp_allocator,
	)
	collision_bytes := slice.to_bytes(collision_raw)
	bytes_read, read_err = os.read_full(file, collision_bytes)
	if read_err != nil {
		fmt.printfln("Failed to read %v: %v", filename, read_err)
		return
	}
	colliders := slice.clone_to_dynamic(collision_raw, allocator = context.temp_allocator)

	if ODIN_DEBUG {
		fmt.printfln("Collision Len %v", collision_len)
		fmt.printfln("Collision dynamic len %v", len(colliders))
	}
	room.collision = colliders


	success = true
	return
}

read_room_transitions_from_file :: proc(
	filename: string,
) -> (
	room: lvl_write.Binary_Room,
	success: bool,
) {
	file, read_err := os.open(filename)
	if read_err != nil {
		fmt.eprintfln("Failed to read %v: %v", filename, read_err)
		return
	}
	defer os.close(file)

	bytes_read: int
	transition_len: int

	// Read ints from the start of the file
	bytes_read = read_int_from_file(file, &transition_len)
	// Read dynamic data from the file
	transition_raw := make(
		[]lvl_write.Binary_Transition,
		transition_len / size_of(lvl_write.Binary_Transition),
		allocator = context.temp_allocator,
	)
	transition_bytes := slice.to_bytes(transition_raw)
	bytes_read, read_err = os.read_full(file, transition_bytes)
	if read_err != nil {
		fmt.printfln("Failed to read %v: %v", filename, read_err)
		return
	}
	transitions := slice.clone_to_dynamic(transition_raw, allocator = context.temp_allocator)

	room.transitions = transitions


	success = true
	return
}

read_room_entities_from_file :: proc(
	filename: string,
) -> (
	room: lvl_write.Binary_Room,
	success: bool,
) {
	file, read_err := os.open(filename)
	if read_err != nil {
		fmt.eprintfln("Failed to read %v: %v", filename, read_err)
		return
	}
	defer os.close(file)

	bytes_read: int
	entities_len_in_bytes: int

	// Read ints from the start of the file
	bytes_read = read_int_from_file(file, &entities_len_in_bytes)
	// Read dynamic data from the file
	entities_raw := make(
		[]tags.Binary_Entity,
		entities_len_in_bytes / size_of(tags.Binary_Entity),
		allocator = context.temp_allocator,
	)
	entities_bytes := slice.to_bytes(entities_raw)
	bytes_read, read_err = os.read_full(file, entities_bytes)
	if read_err != nil {
		fmt.printfln("Failed to read %v: %v", filename, read_err)
		return
	}
	entities := slice.clone_to_dynamic(entities_raw, allocator = context.temp_allocator)

	room.entities = entities

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
	value_bytes := make([]u8, len, allocator = context.temp_allocator)
	n, read_err := os.read_full(file, value_bytes)
	bytes_read = n
	if read_err != nil {
		fmt.printfln("Failed to read %v", read_err)
		return
	}
	destination^ = string(value_bytes)
	return
}
