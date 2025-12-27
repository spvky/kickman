# .rgn
room_count: int -> 8b

# .lvl
image_path_len: int -> 8b
width: int -> 8b
height: int -> 8b
collision_len: int -> 8b
image_path: string -> (image_path_len) * 1b
collision: [dynamic]Binary_Collider -> (collision_len) * 32b
