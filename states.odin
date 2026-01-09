package main

import "core:log"

Player_Flag :: enum u8 {
	Grounded,
	Double_Jump,
	Has_Ball,
	On_Ball,
}

Player_Timed_Flag :: enum u8 {
	Coyote,
	Ignore_Ball,
	No_Badge,
	No_Move,
	No_Control,
	No_Transition,
	In_Slide,
}

Player_Master_Flag :: enum u16 {
	Grounded,
	Double_Jump,
	Has_Ball,
	On_Ball,
	Coyote,
	Ignore_Ball,
	No_Badge,
	No_Move,
	No_Control,
	No_Transition,
	In_Slide,
}
Ball_Flag :: enum u8 {
	Grounded,
	Bounced,
	In_Collider,
}

Ball_Timed_Flag :: enum u8 {
	No_Gravity,
	Coyote,
}

Ball_Master_Flag :: enum u16 {
	Grounded,
	Bounced,
	In_Collider,
	No_Gravity,
	Coyote,
}

Player_Ball_Interaction :: enum u8 {
	Header,
	Bounce,
	Ride,
	Recall,
	Catch,
	Kick,
	Slide,
	Dismount,
	Rev_Shot,
}

@(require_results)
player_has :: proc(set: ..Player_Master_Flag) -> bool {
	player := &world.player

	static: bit_set[Player_Flag;u8]
	timed: bit_set[Player_Timed_Flag;u8]

	for v in set {
		switch v {
		case .Grounded:
			static += {.Grounded}
		case .Double_Jump:
			static += {.Double_Jump}
		case .Has_Ball:
			static += {.Has_Ball}
		case .On_Ball:
			static += {.On_Ball}
		case .Coyote:
			timed += {.Coyote}
		case .Ignore_Ball:
			timed += {.Ignore_Ball}
		case .No_Badge:
			timed += {.No_Badge}
		case .No_Move:
			timed += {.No_Move}
		case .No_Control:
			timed += {.No_Control}
		case .No_Transition:
			timed += {.No_Transition}
		case .In_Slide:
			timed += {.In_Slide}
		}
	}
	return static <= player.flags && timed <= player.timed_flags
}

@(require_results)
player_lacks :: proc(set: ..Player_Master_Flag) -> (lacks: bool) {
	player := &world.player
	lacks = true

	for v in set {
		switch v {
		case .Grounded:
			if .Grounded in player.flags {
				lacks = false
				return
			}
		case .Double_Jump:
			if .Double_Jump in player.flags {
				lacks = false
				return
			}
		case .Has_Ball:
			if .Has_Ball in player.flags {
				lacks = false
				return
			}
		case .On_Ball:
			if .On_Ball in player.flags {
				lacks = false
				return
			}
		case .Coyote:
			if .Coyote in player.timed_flags {
				lacks = false
				return
			}
		case .Ignore_Ball:
			if .Ignore_Ball in player.timed_flags {
				lacks = false
				return
			}
		case .No_Badge:
			if .No_Badge in player.timed_flags {
				lacks = false
				return
			}
		case .No_Move:
			if .No_Move in player.timed_flags {
				lacks = false
				return
			}
		case .No_Control:
			if .No_Control in player.timed_flags {
				lacks = false
				return
			}
		case .No_Transition:
			if .No_Transition in player.timed_flags {
				lacks = false
				return
			}
		case .In_Slide:
			if .In_Slide in player.timed_flags {
				lacks = false
				return
			}
		}
	}
	return lacks
}

@(require_results)
ball_has :: proc(set: ..Ball_Master_Flag) -> bool {
	ball := &world.ball

	static: bit_set[Ball_Flag;u8]
	timed: bit_set[Ball_Timed_Flag;u8]

	for v in set {
		switch v {
		case .Grounded:
			static += {.Grounded}
		case .Bounced:
			static += {.Bounced}
		case .In_Collider:
			static += {.In_Collider}
		case .No_Gravity:
			timed += {.No_Gravity}
		case .Coyote:
			timed += {.Coyote}
		}
	}
	return static <= ball.flags && timed <= ball.timed_flags
}

@(require_results)
ball_lacks :: proc(set: ..Ball_Master_Flag) -> (lacks: bool) {
	ball := &world.ball
	lacks = true
	for v in set {
		switch v {
		case .Grounded:
			if .Grounded in ball.flags {
				lacks = false
				return
			}
		case .Bounced:
			if .Bounced in ball.flags {
				lacks = false
				return
			}
		case .In_Collider:
			if .In_Collider in ball.flags {
				lacks = false
				return
			}
		case .No_Gravity:
			if .No_Gravity in ball.timed_flags {
				lacks = false
				return
			}
		case .Coyote:
			if .Coyote in ball.timed_flags {
				lacks = false
				return
			}
		}
	}
	return
}
player_ball_can_interact :: proc() -> bool {
	return player_lacks(.Ignore_Ball) || !ball_is(.Carried)
}

player_can :: proc(i: Player_Ball_Interaction) -> (able: bool) {
	player := &world.player
	ball := &world.ball
	if player_has(.Ignore_Ball) do return
	switch i {
	case .Kick:
		able =
			player_has(.Has_Ball) &&
			player_is(.Idle, .Running, .Skidding, .Rising, .Falling) &&
			ball_is(.Carried) &&
			ball_lacks(.In_Collider)
	case .Slide:
		able =
			player_has(.Grounded) &&
			player_is(.Idle, .Running, .Skidding, .Crouching, .Sliding) &&
			player_lacks(.In_Slide)
	case .Catch:
		able =
			player_lacks(.Has_Ball, .Ignore_Ball) &&
				(player_is(.Idle, .Running, .Skidding, .Crouching) &&
						ball_is(.Free, .Recalling)) ||
			(player_is(.Rising, .Falling) && ball_is(.Recalling))
	case .Header:
		able =
			player_lacks(.Ignore_Ball) &&
			player_is(.Idle, .Running, .Skidding, .Rising, .Falling) &&
			ball_is(.Free)
	case .Ride:
		able = player_lacks(.Ignore_Ball) && ball_is(.Revved)
	case .Bounce:
		able = player_lacks(.Ignore_Ball, .Grounded) && ball_is(.Free)
	case .Recall:
		able = player_lacks(.No_Badge) && ball_has(.Bounced) && ball_is(.Revved, .Free)
	case .Dismount:
		able = player_is(.Riding)
	case .Rev_Shot:
		able = player_is(.Sliding) && ball_is(.Free)
	}
	return
}
