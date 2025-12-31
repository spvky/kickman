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

@(require_results)
player_has :: proc(set: ..Player_Master_State) -> bool {
	player := &world.player

	static: bit_set[Player_State;u8]
	timed: bit_set[Player_Timed_State;u8]

	for v in set {
		switch v {
		case .Grounded:
			static += {.Grounded}
		case .Double_Jump:
			static += {.Double_Jump}
		case .Walking:
			static += {.Walking}
		case .Riding:
			static += {.Riding}
		case .Coyote:
			timed += {.Coyote}
		case .Ignore_Ball:
			timed += {.Ignore_Ball}
		case .No_Badge:
			timed += {.No_Badge}
		case .No_Move:
			timed += {.No_Move}
		case .No_Transition:
			timed += {.No_Transition}
		}
	}
	return static <= player.state_flags && timed <= player.timed_state_flags
}

@(require_results)
player_lacks :: proc(set: ..Player_Master_State) -> (lacks: bool) {
	player := &world.player
	lacks = true

	for v in set {
		switch v {
		case .Grounded:
			if .Grounded in player.state_flags {
				lacks = false
				return
			}
		case .Double_Jump:
			if .Double_Jump in player.state_flags {
				lacks = false
				return
			}
		case .Walking:
			if .Walking in player.state_flags {
				lacks = false
				return
			}
		case .Riding:
			if .Riding in player.state_flags {
				lacks = false
				return
			}
		case .Coyote:
			if .Coyote in player.timed_state_flags {
				lacks = false
				return
			}
		case .Ignore_Ball:
			if .Ignore_Ball in player.timed_state_flags {
				lacks = false
				return
			}
		case .No_Badge:
			if .No_Badge in player.timed_state_flags {
				lacks = false
				return
			}
		case .No_Move:
			if .No_Move in player.timed_state_flags {
				lacks = false
				return
			}
		case .No_Transition:
			if .No_Transition in player.timed_state_flags {
				lacks = false
				return
			}
		}
	}
	return lacks
}

@(require_results)
ball_has :: proc(set: ..Ball_Master_State) -> bool {
	ball := &world.ball

	static: bit_set[Ball_State;u8]
	timed: bit_set[Ball_Timed_State;u8]

	for v in set {
		switch v {
		case .Carried:
			static += {.Carried}
		case .Grounded:
			static += {.Grounded}
		case .Recalling:
			static += {.Recalling}
		case .Revved:
			static += {.Revved}
		case .Bounced:
			static += {.Bounced}
		case .No_Gravity:
			timed += {.No_Gravity}
		case .Coyote:
			timed += {.Coyote}
		}
	}
	return static <= ball.state_flags && timed <= ball.timed_state_flags
}

@(require_results)
ball_lacks :: proc(set: ..Ball_Master_State) -> (lacks: bool) {
	ball := &world.ball
	lacks = true
	for v in set {
		switch v {
		case .Carried:
			if .Carried in ball.state_flags {
				lacks = false
				return
			}
		case .Grounded:
			if .Grounded in ball.state_flags {
				lacks = false
				return
			}
		case .Recalling:
			if .Recalling in ball.state_flags {
				lacks = false
				return
			}
		case .Revved:
			if .Revved in ball.state_flags {
				lacks = false
				return
			}
		case .Bounced:
			if .Bounced in ball.state_flags {
				lacks = false
				return
			}
		case .No_Gravity:
			if .No_Gravity in ball.timed_state_flags {
				lacks = false
				return
			}
		case .Coyote:
			if .Coyote in ball.timed_state_flags {
				lacks = false
				return
			}
		}
	}
	return
}
player_ball_can_interact :: proc() -> bool {
	return player_lacks(.Ignore_Ball) || player_lacks(.Riding) || ball_lacks(.Carried)
}

player_can :: proc(i: Player_Ball_Interaction) -> (able: bool) {
	player := &world.player
	ball := &world.ball
	if player_has(.Ignore_Ball) || player_has(.Riding) || ball_has(.Carried) do return
	switch i {
	case .Catch:
		able = ball_lacks(.Revved) && (player_has(.Grounded) || ball_has(.Recalling))
	case .Header:
		able = ball_lacks(.Revved, .Recalling)
	case .Ride:
		able = ball_has(.Revved, .Bounced) && ball_lacks(.Recalling)
	case .Bounce:
		able = player_lacks(.Grounded) && ball_lacks(.Revved, .Recalling) && player.velocity.y > 0
	case .Recall:
		able = ball_has(.Bounced) && player_lacks(.Riding, .No_Badge) && ball_lacks(.Carried)
	}
	return
}
