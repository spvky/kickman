package level_read

import lvl_write "../level_write"
import tags "../tags"
import "core:fmt"
import "core:os"
import "core:slice"
import "core:strings"
import "core:time"

read_room_collision_from_file :: proc(
	filename: string,
) -> (
	colliders: [dynamic]lvl_write.Binary_Collider,
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
	bytes_read = read_fixed_from_file(file, &collision_len)
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
	colliders = slice.clone_to_dynamic(collision_raw, allocator = context.temp_allocator)
	if ODIN_DEBUG {
		fmt.printfln("Collision Len %v", collision_len)
		fmt.printfln("Collision dynamic len %v", len(colliders))
	}
	success = true
	return
}

read_room_transitions_from_file :: proc(
	filename: string,
) -> (
	transitions: [dynamic]lvl_write.Binary_Transition,
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
	bytes_read = read_fixed_from_file(file, &transition_len)
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
	transitions = slice.clone_to_dynamic(transition_raw, allocator = context.temp_allocator)
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
	bytes_read = read_fixed_from_file(file, &entities_len_in_bytes)
	// Read dynamic data from the file
	entities_raw := make(
		[]tags.Entity,
		entities_len_in_bytes / size_of(tags.Entity),
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

read_room_tooltips_from_file :: proc(
	filename: string,
) -> (
	tooltips: [dynamic]tags.Tooltip,
	success: bool,
) {
	file, read_err := os.open(filename)
	if read_err != nil {
		fmt.eprintfln("Failed to read %v: %v", filename, read_err)
		return
	}
	defer os.close(file)

	bytes_read: int
	tooltip_count: int
	bytes_read = read_fixed_from_file(file, &tooltip_count)
	tooltips = make([dynamic]tags.Tooltip, 0, tooltip_count)
	for i in 0 ..< tooltip_count {
		tooltip: tags.Tooltip
		bytes_read += read_string_from_file(file, &tooltip.message)
		bytes_read += read_fixed_from_file(file, &tooltip.pos)
		bytes_read += read_fixed_from_file(file, &tooltip.display_point)
		bytes_read += read_fixed_from_file(file, &tooltip.extents)
		append(&tooltips, tooltip)
	}
	success = true
	return
}

// Read a fixed (i.e non dynamic) type from the passed file, into the given rawptr
read_fixed_from_file :: #force_inline proc(
	file: os.Handle,
	destination: ^$T,
) -> (
	bytes_read: int,
) {
	n, err := os.read_ptr(file, destination, size_of(T))
	if err != nil {
		fmt.printfln("Failed to read %v", err)
	}
	bytes_read = n
	return
}

// Reads string from passed file into pointer, assuming the string is preceded by its length as an INT, allocates using context.allocator
read_string_from_file :: #force_inline proc(
	file: os.Handle,
	destination: ^string,
	allocator := context.allocator,
) -> (
	bytes_read: int,
) {
	str_len: int
	bytes_read += read_fixed_from_file(file, &str_len)
	value_bytes := make([]u8, str_len, allocator = allocator)
	n, read_err := os.read_full(file, value_bytes)
	bytes_read = n
	if read_err != nil {
		fmt.printfln("Failed to read %v", read_err)
		return
	}
	destination^ = string(value_bytes)
	return
}
