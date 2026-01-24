package main

import "core:log"
import "core:math"

Ball :: struct {
	using rigidbody: Rigidbody,
	ignore_player:   f32,
	spin:            f32,
	rotation:        f32,
	f_color:         [4]f32,
	target_f_color:  [4]f32,
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

init_ball :: proc() {
	subscribe_event(.Room_Change, summon_ball)
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
	ball.radius = 4
	switch ball.state {
	case .Free:
		ball.target_f_color = {255, 255, 255, 255}
	case .Riding, .Revved:
		ball.target_f_color = {203, 178, 112, 255}
	case .Recalling:
		ball.target_f_color = {165, 134, 236, 255}
	}
	ball.f_color = math.lerp(ball.f_color, ball.target_f_color, delta * 10)
}

ride_ball :: proc() {
	world.ball.state = .Riding
	override_player_state(.Riding)
}

summon_ball :: proc(event: Event) {
	player := &world.player
	ball := &world.ball
	if ball.state != .Riding {
		ball.state = .Free
		ball.f_color = {255, 255, 255, 0}
		player_feet := player.translation + {0, player.radius / 2}
		ball_target_position := Vec2{0, player_feet.y - 8}
		if point, ok := player.recall_cast_point.?; ok {
			ball_target_position.x = point.x + (-player.facing * (ball.radius + 0.5))
		} else {
			ball_target_position.x = player.translation.x + (player.facing * player.radius * 8)
		}
		ball.translation = ball_target_position
		ball.velocity = VEC_0
		player_t_remove(.Ignore_Ball)
	}
}

recall_ball :: proc(ball: ^Ball) {
	player_t_add(.No_Badge, 1.5)
	ball.state = .Recalling
	ball_t_add(.Recall_Rising, 0.5)
	consume_action(.Badge)
}
