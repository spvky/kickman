package main

import "core:math"

Player_State :: enum {
	// Grounded
	Idle,
	Running,
	Skidding,
	Sliding,
	Crouching,
	Crouch_Skidding,
	// Airborne
	Rising,
	Falling,
	// Override States
	Riding,
}

Ball_State :: enum {
	Carried,
	Free,
	Recalling,
	Revved,
	Riding,
}

determine_player_state :: proc() {
	player := &world.player
	if player_has(.On_Ball) {
		player.state = .Riding
		return
	}
	if player_has(.Grounded) {
		if player_has(.In_Slide) {
			player.state = .Sliding
			return
		}
		if is_action_held(.Crouch) {
			player.state = .Crouching
			return
		}

		if math.sign(player.velocity.x) == math.sign(player.movement_delta) {
			if player.movement_delta != 0 {
				player.state = .Running
				return
			} else {
				player.state = .Idle
				return
			}
		} else {
			if is_action_held(.Crouch) {
				player.state = .Crouch_Skidding
				return
			} else {
				player.state = .Skidding
				return
			}
		}
	} else {
		if player.velocity.y < 0 {
			player.state = .Rising
			return
		} else {
			player.state = .Falling
			return
		}
	}
}
