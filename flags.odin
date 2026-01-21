package main

import "core:time"

Player_Flag :: enum u16 {
	Grounded,
	Double_Jump,
	Has_Ball,
	Bounced,
}

Player_Timed_Flag :: enum u16 {
	Coyote,
	Ignore_Ball,
	No_Badge,
	No_Control,
	No_Transition,
	In_Slide,
	Ignore_Oneways,
	Just_Bounced,
	Just_Jumped,
	Kicking,
	No_Turn,
	No_Cling,
	Outside_Force,
}

Player_Master_Flag :: enum u32 {
	Grounded,
	Double_Jump,
	Has_Ball,
	Bounced,
	Coyote,
	Ignore_Ball,
	No_Badge,
	No_Control,
	No_Transition,
	In_Slide,
	Ignore_Oneways,
	Just_Bounced,
	Just_Jumped,
	Kicking,
	No_Turn,
	No_Cling,
	Outside_Force,
}
Ball_Flag :: enum u8 {
	Grounded,
	Bounced,
	In_Collider,
}

Ball_Timed_Flag :: enum u8 {
	No_Gravity,
	Coyote,
	Recall_Rising,
}

Ball_Master_Flag :: enum u16 {
	Grounded,
	Bounced,
	In_Collider,
	No_Gravity,
	Coyote,
	Recall_Rising,
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

	static: bit_set[Player_Flag;u16]
	timed: bit_set[Player_Timed_Flag;u16]

	for v in set {
		switch v {
		case .Grounded:
			static += {.Grounded}
		case .Double_Jump:
			static += {.Double_Jump}
		case .Has_Ball:
			static += {.Has_Ball}
		case .Bounced:
			static += {.Bounced}
		case .Coyote:
			timed += {.Coyote}
		case .Ignore_Ball:
			timed += {.Ignore_Ball}
		case .No_Badge:
			timed += {.No_Badge}
		case .No_Control:
			timed += {.No_Control}
		case .No_Transition:
			timed += {.No_Transition}
		case .In_Slide:
			timed += {.In_Slide}
		case .Ignore_Oneways:
			timed += {.Ignore_Oneways}
		case .Just_Bounced:
			timed += {.Just_Bounced}
		case .Just_Jumped:
			timed += {.Just_Jumped}
		case .Kicking:
			timed += {.Kicking}
		case .No_Turn:
			timed += {.No_Turn}
		case .No_Cling:
			timed += {.No_Cling}
		case .Outside_Force:
			timed += {.Outside_Force}
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
		case .Bounced:
			if .Bounced in player.flags {
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
		case .Ignore_Oneways:
			if .Ignore_Oneways in player.timed_flags {
				lacks = false
				return
			}
		case .Just_Bounced:
			if .Just_Bounced in player.timed_flags {
				lacks = false
			}
			return
		case .Just_Jumped:
			if .Just_Jumped in player.timed_flags {
				lacks = false
			}
		case .Kicking:
			if .Kicking in player.timed_flags {
				lacks = false
			}
		case .No_Turn:
			if .No_Turn in player.timed_flags {
				lacks = false
			}
		case .No_Cling:
			if .No_Cling in player.timed_flags {
				lacks = false
			}
		case .Outside_Force:
			if .Outside_Force in player.timed_flags {
				lacks = false
			}
		}
	}
	return lacks
}

player_add :: proc(flag: Player_Flag) {
	player := &world.player
	player.flags += {flag}
}

player_t_add :: proc(flag: Player_Timed_Flag, time: f32) {
	player := &world.player
	player.timed_flags += {flag}
	player.flag_timers[flag] = time
}

player_remove :: proc(flag: Player_Flag) {
	player := &world.player
	player.flags -= {flag}
}

player_t_remove :: proc(flag: Player_Timed_Flag) {
	player := &world.player
	player.timed_flags -= {flag}
	player.flag_timers[flag] = 0
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
		case .Recall_Rising:
			timed += {.Recall_Rising}
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
		case .Recall_Rising:
			if .Recall_Rising in ball.timed_flags {
				lacks = false
				return
			}
		}
	}
	return
}

ball_add :: proc(flag: Ball_Flag) {
	ball := &world.ball
	ball.flags += {flag}
}

ball_t_add :: proc(flag: Ball_Timed_Flag, time: f32) {
	ball := &world.ball
	ball.timed_flags += {flag}
	ball.flag_timers[flag] = time
}

ball_remove :: proc(flag: Ball_Flag) {
	ball := &world.ball
	ball.flags -= {flag}
}

ball_t_remove :: proc(flag: Ball_Timed_Flag) {
	ball := &world.ball
	ball.timed_flags -= {flag}
	ball.flag_timers[flag] = 0
}

player_ball_can_interact :: proc() -> bool {
	return player_lacks(.Ignore_Ball, .Has_Ball, .Ignore_Ball) && !player_is(.Riding)
}

player_can :: proc(i: Player_Ball_Interaction) -> (able: bool) {
	player := &world.player
	ball := &world.ball
	if player_has(.Ignore_Ball) do return
	switch i {
	case .Kick:
		able = player_is(.Idle, .Running, .Skidding, .Rising, .Falling) && player_lacks(.Kicking)
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
		able = player_lacks(.Ignore_Ball) && player.badge_type == .Sisyphus
	case .Bounce:
		able = player_lacks(.Ignore_Ball, .Grounded) && ball_is(.Free)
	case .Recall:
		able = player_lacks(.No_Badge) && ball_has(.Bounced) && player.badge_type == .Striker
	case .Dismount:
		able = player_is(.Riding)
	case .Rev_Shot:
		able = player_is(.Sliding) && ball_is(.Free)
	}
	return
}
