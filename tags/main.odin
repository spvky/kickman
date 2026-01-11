package tags

Collider_Flag :: enum u8 {
	Standable,
	Clingable,
	Oneway,
	Ball_Only,
}

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

Entity :: struct {
	tag:  Entity_Tag,
	pos:  [2]f32,
	data: Entity_Data,
}

Entity_Data :: union {
	Movable_Block_Data,
	Trigger_Data,
}

Movable_Block_Data :: struct {
	trigger_index: int,
	positions:     [2][2]f32,
	extents:       [2]f32,
	velocity:      [2]f32,
	speed:         f32,
}

Trigger_Data :: struct {
	on:              bool,
	touching_player: bool,
}

Tooltip :: struct {
	message:         string,
	pos:             [2]f32,
	display_point:   [2]f32,
	extents:         [2]f32,
	touching_player: bool,
	current_opacity: f32,
}
