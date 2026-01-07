package main

import "core:log"
import "core:math"

// Idle
// -> Run
// -> Rise
// -> Fall
// -> Crouch
//
// Run
// -> Skid
// -> Slide
// -> Rise
// -> Fall
// -> Idle (when you don't pass a certain speed)

// Fall
// -> Idle
// -> Run
// -> Rise
// -> Crouch
// -> Skid
// -> Slide

// Skid
// -> Idle
// -> Slide
// -> Rising
// -> Falling
// -> Running

// Rise -> Fall


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
	log.debugf("State Transition: %v", data)

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
				player.velocity.x = player.facing * max_speed * 0.9
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

determine_player_state :: proc() {
	player := &world.player
	new_state: Player_State
	// switch player.state {
	// case .Idle:
	// 	if is_action_held(.Crouch) && player_lacks(.In_Slide) {
	// 		new_state = .Crouching
	// 		break
	//
	// 		if player.velocity.x == 0 && player.movement_delta != 0 {
	// 			new_state = .Idle
	// 			break
	// 		}
	// 	}
	// case .Running:
	// case .Skidding:
	// case .Sliding:
	// case .Crouching:
	// case .Crouch_Skidding:
	// case .Rising:
	// case .Falling:
	// case .Riding:
	// }
	if player_is(.Riding) {
		return
	}
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
