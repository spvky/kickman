package main

Player_State :: enum u8 {
	Grounded,
	Double_Jump,
	Walking,
	Riding,
}

Player_Timed_State :: enum u8 {
	Coyote,
	Ignore_Ball,
	No_Badge,
	No_Move,
	No_Transition,
}

Player_Master_State :: enum u16 {
	Grounded,
	Double_Jump,
	Walking,
	Riding,
	Coyote,
	Ignore_Ball,
	No_Badge,
	No_Move,
	No_Transition,
}
Ball_State :: enum u8 {
	Carried,
	Grounded,
	Recalling,
	Revved,
	Bounced,
}

Ball_Timed_State :: enum u8 {
	No_Gravity,
	Coyote,
}

Ball_Master_State :: enum u16 {
	Carried,
	Grounded,
	Recalling,
	Revved,
	Bounced,
	No_Gravity,
	Coyote,
}

Player_Ball_Interaction :: enum u8 {
	Header,
	Bounce,
	Ride,
	Recall,
	Catch,
}

// Check if the player has the passed state flag
@(require_results)
player_has_single :: proc(flag: Player_Master_State) -> (contains: bool) {
	switch flag {
	case .Grounded:
		contains = .Grounded in world.player.state_flags
	case .Double_Jump:
		contains = .Double_Jump in world.player.state_flags
	case .Walking:
		contains = .Walking in world.player.state_flags
	case .Riding:
		contains = .Riding in world.player.state_flags
	case .Coyote:
		contains = .Coyote in world.player.timed_state_flags
	case .Ignore_Ball:
		contains = .Ignore_Ball in world.player.timed_state_flags
	case .No_Badge:
		contains = .No_Badge in world.player.timed_state_flags
	case .No_Move:
		contains = .No_Move in world.player.timed_state_flags
	case .No_Transition:
		contains = .No_Transition in world.player.timed_state_flags
	}
	return contains
}

@(require_results)
player_has_multiple :: proc(set: bit_set[Player_Master_State]) -> bool {
	player := &world.player

	p_static: bit_set[Player_State;u8]
	p_timed: bit_set[Player_Timed_State;u8]

	for v in set {
		switch v {
		case .Grounded:
			p_static += {.Grounded}
		case .Double_Jump:
			p_static += {.Double_Jump}
		case .Walking:
			p_static += {.Walking}
		case .Riding:
			p_static += {.Riding}
		case .Coyote:
			p_timed += {.Coyote}
		case .Ignore_Ball:
			p_timed += {.Ignore_Ball}
		case .No_Badge:
			p_timed += {.No_Badge}
		case .No_Move:
			p_timed += {.No_Move}
		case .No_Transition:
			p_timed += {.No_Transition}
		}
	}

	return p_static <= player.state_flags && p_timed <= player.timed_state_flags

}

player_has :: proc {
	player_has_single,
// player_has_multiple,
}

// Check if the ball has the passed state flag
@(require_results)
ball_has_single :: proc(flag: Ball_Master_State) -> (contains: bool) {
	switch flag {
	case .Carried:
		contains = .Carried in world.ball.state_flags
	case .Grounded:
		contains = .Grounded in world.ball.state_flags
	case .Recalling:
		contains = .Recalling in world.ball.state_flags
	case .Revved:
		contains = .Revved in world.ball.state_flags
	case .Bounced:
		contains = .Bounced in world.ball.state_flags
	case .No_Gravity:
		contains = .No_Gravity in world.ball.timed_state_flags
	case .Coyote:
		contains = .Coyote in world.ball.timed_state_flags
	}
	return contains
}

ball_has :: proc {
	ball_has_single,
}

player_ball_can_interact :: proc() -> bool {
	return !player_has(.Ignore_Ball) || !player_has(.Riding) || !ball_has(.Carried)
}

player_can :: proc(i: Player_Ball_Interaction) -> (able: bool) {
	player := &world.player
	ball := &world.ball
	if player_has(.Ignore_Ball) || player_has(.Riding) || ball_has(.Carried) do return
	switch i {
	case .Catch:
		able = !ball_has(.Revved) && (player_has(.Grounded) || ball_has(.Recalling))
	case .Header:
		able = !ball_has(.Revved) && !ball_has(.Recalling)
	case .Ride:
		able = ball_has(.Revved) && ball_has(.Bounced) && !ball_has(.Recalling)
	case .Bounce:
		able =
			!player_has(.Grounded) &&
			!ball_has(.Revved) &&
			!ball_has(.Recalling) &&
			player.velocity.y > 0
	case .Recall:
		able =
			ball_has(.Bounced) &&
			!player_has(.Riding) &&
			!ball_has(.Carried) &&
			!player_has(.No_Badge)
	}
	return
}
