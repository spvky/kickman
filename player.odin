package main

Player :: struct {
	using rigidbody: Rigidbody,
	move_delta:      f32,
	facing:          f32,
	carry_pos:       f32,
	state_flags:     bit_set[Player_State],
	has_ball:        bool,
}

Player_State :: enum u8 {
	Grounded,
	DoubleJump,
}

Ball :: struct {
	using rigidbody: Rigidbody,
	carried:         bool,
}
