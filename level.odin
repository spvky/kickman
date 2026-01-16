package main

import tags "./tags/"

Region :: struct {
	tag: tags.Region_Tag,
}

Room_Transition :: struct {
	tag:                  tags.Room_Tag,
	transition_position:  [2]f32,
	touching_player:      bool,
	prev_touching_player: bool,
	active:               bool,
	using aabb:           AABB,
}

Spawn_Point :: struct {
	room_tag: tags.Room_Tag,
	position: Vec2,
}
