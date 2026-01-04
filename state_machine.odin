package main

State :: enum {
	// Grounded
	Idle,
	Running,
	Skidding,
	Sliding,
	Crouching,
	// Airborne
	Rising,
	Falling,
	// Special
	Riding,
}

Flags :: enum {
	Grounded,
	Double_Jump,
	Has_Ball,
}

Timed_Flags :: enum {
	Coyote,
	Ignore_Ball,
	No_Badge,
	No_Control,
	No_Transition,
}

determine_player_state :: proc() {
	// has Grounded {
	// lacks No_Control {
	// Idle: velocity.x == 0
	// Crouching: is holding down
	// Running: velocity.x != 0
	// Sliding: has Sliding
	// } else {
	// //
	// }
	//} else
	// Falling: velocity.y > 0
	// Rising: velocity.y < 0
}
