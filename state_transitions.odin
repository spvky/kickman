package main

import "core:log"
import "core:math"

determine_state_from_idle :: #force_inline proc(player: ^Player) -> (state: Player_State) {
	state = .Idle
	if player_has(.Grounded) {
		if is_action_held(.Crouch) {
			state = .Crouching
		} else if player.movement_delta != 0 {
			state = .Running
		}
	} else {
		if player.velocity.y >= 0 {
			state = .Falling
		} else {
			state = .Rising
		}
	}
	return
}

determine_state_from_running :: #force_inline proc(player: ^Player) -> (state: Player_State) {
	state = .Running
	if player_has(.Grounded) {
		if is_action_held(.Crouch) {
			state = .Sliding
		} else if player.movement_delta == 0 {
			if math.abs(player.velocity.x) < 20 {
				state = .Idle
			} else {
				state = .Skidding
			}
		} else if math.sign(player.movement_delta) != math.sign(player.velocity.x) {
			state = .Skidding
		}
	} else {
		if player.velocity.y >= 0 {
			state = .Falling
		} else {
			state = .Rising
		}
	}
	return
}

determine_state_from_skidding :: #force_inline proc(player: ^Player) -> (state: Player_State) {
	state = .Skidding
	if player_has(.Grounded) {
		if is_action_held(.Crouch) {
			state = .Sliding
		} else if player.movement_delta == 0 {
			if math.abs(player.velocity.x) < 20 {
				state = .Idle
			}
		} else if math.sign(player.movement_delta) == math.sign(player.velocity.x) {
			state = .Running
		}
	} else {
		if player.velocity.y >= 0 {
			state = .Falling
		} else {
			state = .Rising
		}
	}
	return
}

determine_state_from_sliding :: #force_inline proc(player: ^Player) -> (state: Player_State) {
	state = .Sliding
	if player_has(.Grounded) {
		if math.abs(player.velocity.x) <= 5 {
			if is_action_held(.Crouch) {
				state = .Crouching
			} else {
				state = .Idle
			}
		}
	} else {
		if player.velocity.y >= 0 {
			state = .Falling
		} else {
			state = .Rising
		}
	}
	return
}

determine_state_from_crouching :: #force_inline proc(player: ^Player) -> (state: Player_State) {
	state = .Crouching
	if player_has(.Grounded) {
		if player_has(.In_Slide) {
			state = .Sliding
		}
		if !is_action_held(.Crouch) {
			state = .Idle
		}
	} else {
		if player.velocity.y >= 0 {
			state = .Falling
		} else {
			state = .Rising
		}
	}
	return
}

determine_state_from_rising :: #force_inline proc(player: ^Player) -> (state: Player_State) {
	state = .Rising
	if player.velocity.y >= 0 {
		state = .Falling
	}
	return
}

determine_state_from_falling :: #force_inline proc(player: ^Player) -> (state: Player_State) {
	state = .Falling
	if player_has(.Grounded) {
		if is_action_held(.Crouch) {
			state = .Crouching
		} else {
			if player.movement_delta == 0 {
				state = .Idle
			} else {
				if math.sign(player.movement_delta) == math.sign(player.velocity.x) {
					state = .Running
				} else {
					state = .Skidding
				}
			}
		}
		if player_has(.In_Slide) {
			state = .Idle
		}
	} else {
		if player.velocity.y < 0 {
			state = .Rising
		}
	}
	return
}
