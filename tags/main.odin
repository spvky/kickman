package tags

Room_Tag :: struct {
	region_tag: Region_Tag,
	room_index: u8,
}

Region_Tag :: enum u8 {
	tutorial,
}

Entity_Tag :: enum {
	Lever,
	Button,
	Movable_Block,
}

Binary_Entity :: struct {
	tag:  Entity_Tag,
	pos:  [2]f32,
	data: Binary_Entity_Data,
}

Binary_Entity_Data :: union {
	Binary_Movable_Block_Data,
}

Binary_Movable_Block_Data :: struct {
	trigger_index: int,
	positions:     [2][2]f32,
	extents:       [2]f32,
}
