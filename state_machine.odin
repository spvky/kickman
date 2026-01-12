package main

import "core:log"
import "core:math"

Player_State :: enum {
	// Grounded
	Idle,
	Running,
	Skidding,
	Sliding,
	Crouching,
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

// Returns true if the player state matches ANY of the passed states
player_is :: proc(states: ..Player_State) -> (matches: bool) {
	player := &world.player
	for v in states {
		if player.state == v {
			matches = true
		}
	}
	return
}

// Returns true if the ball state matches ANY of the passed states
ball_is :: proc(states: ..Ball_State) -> (matches: bool) {
	ball := &world.ball
	for v in states {
		if ball.state == v {
			matches = true
		}
	}
	return
}

handle_state_transitions :: proc() {
	player := &world.player
	if player.state != player.prev_state {
		publish_event(
			.Player_State_Transition,
			Event_Player_State_Transition{player.prev_state, player.state},
		)
	}
	player.prev_state = player.state
}

player_state_transition_listener :: proc(event: Event) {
	data := event.payload.(Event_Player_State_Transition)
	player := &world.player

	// Should handle all transitions here
	#partial switch data.entered {
	case .Skidding:
		if player.movement_delta != 0 {
			player.facing = player.movement_delta
		}
	case .Running:
		if data.exited == .Idle {
		}
		if data.exited == .Skidding {
			if player.run_direction != player.facing {
				speed_to_add := is_action_held(.Dash) ? dash_speed : run_speed
				player.velocity.x = player.facing * speed_to_add * 0.9
			}
		}
		player.run_direction = player.facing
	}
}

override_player_state :: proc(state: Player_State) {
	world.player.state = state
}


manage_player_state :: proc() {
	player := &world.player
	state := player.state
	switch player.state {
	case .Idle:
		state = determine_state_from_idle(player)
	case .Running:
		state = determine_state_from_running(player)
	case .Skidding:
		state = determine_state_from_skidding(player)
	case .Sliding:
		state = determine_state_from_sliding(player)
	case .Crouching:
		state = determine_state_from_crouching(player)
	case .Rising:
		state = determine_state_from_rising(player)
	case .Falling:
		state = determine_state_from_falling(player)
	case .Riding:
	}
	player.state = state
}

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
			// state = .Running
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
		if player_has(.In_Slide) {
			if math.abs(player.velocity.x) <= 25 {
				if is_action_held(.Crouch) {
					state = .Crouching
				} else {
					state = .Idle
				}
			}
		} else {
			if is_action_held(.Crouch) {
				if math.abs(player.velocity.x) <= 25 {
					state = .Crouching
				}
			} else if player.movement_delta != 0 {
				state = .Running
			} else {
				state = .Idle
			}
		}
	} else {
		if player.velocity.y >= 0 {
			state = .Falling
			player.flag_timers[.In_Slide] = 0
		} else {
			state = .Rising
			player.flag_timers[.In_Slide] = 0
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
