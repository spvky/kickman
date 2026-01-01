package main

import tags "./tags/"

Region :: struct {
	tag: tags.Region_Tag,
}

Room_Transition :: struct {
	tag:                 tags.Room_Tag,
	transition_position: [2]f32,
	using aabb:          AABB,
}
