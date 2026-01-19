package main

import "core:math"

Ball :: struct {
	using rigidbody: Rigidbody,
	ignore_player:   f32,
	spin:            f32,
	state:           Ball_State,
	flags:           bit_set[Ball_Flag;u8],
	timed_flags:     bit_set[Ball_Timed_Flag;u8],
	flag_timers:     [Ball_Timed_Flag]f32,
	juice_values:    [Ball_Juice_Values]f32,
}

Ball_Juice_Values :: enum {
	Rev_Flash,
	Sigil_Rotation,
}

manage_ball_juice_values :: proc(delta: f32) {
	ball := &world.ball
	for v in Ball_Juice_Values {
		switch v {
		case .Rev_Flash:
			rev_timer := &ball.juice_values[.Rev_Flash]
			rev_timer^ += delta
			if rev_timer^ > math.PI {
				rev_timer^ = 0
			}
		case .Sigil_Rotation:
			sigil_rot := &ball.juice_values[.Sigil_Rotation]
			if ball_is(.Revved) {
				sigil_rot^ += delta * 720
			} else if ball_is(.Recalling) {
				sigil_rot^ += delta * 360
			}
		}
	}
}

manage_ball_flags :: proc(delta: f32) {
	ball := &world.ball
	for v in Ball_Timed_Flag {
		timer := &ball.flag_timers[v]
		timer^ = math.clamp(timer^ - delta, 0, 10)
		if timer^ > 0.0 {
			ball.timed_flags += {v}
		} else {
			ball.timed_flags -= {v}
		}
	}
}

catch_ball :: proc() {
	player := &world.player
	ball := &world.ball
	ball.state = .Carried
	ball.flags -= {.Bounced}
	ball.velocity = Vec2{0, 0}
	ball.translation = player_foot_position()
	player.flags += {.Has_Ball}
}
