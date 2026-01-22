package main

import "core:log"
import "core:math"

Ball :: struct {
	using rigidbody: Rigidbody,
	ignore_player:   f32,
	spin:            f32,
	rotation:        f32,
	f_color:         [3]f32,
	target_f_color:  [3]f32,
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
			if ball_is(.Recalling) {
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

manage_ball_apperance :: proc(delta: f32) {
	ball := &world.ball
	ball.radius = 3
	switch ball.state {
	case .Free:
		ball.target_f_color = {255, 255, 255}
	case .Riding, .Revved:
		ball.target_f_color = {203, 178, 112}
	case .Recalling:
		ball.target_f_color = {165, 134, 236}
	}
	ball.f_color = math.lerp(ball.f_color, ball.target_f_color, delta * 10)


}

ride_ball :: proc() {
	world.ball.state = .Riding
	override_player_state(.Riding)
}

summon_ball :: proc() {
}

recall_ball :: proc(ball: ^Ball) {
	player_t_add(.No_Badge, 1.5)
	ball.state = .Recalling
	ball_t_add(.Recall_Rising, 0.5)
	consume_action(.Badge)
}
