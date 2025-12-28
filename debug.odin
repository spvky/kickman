package main

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

player_debug :: proc() {
	player := world.player
	ball := world.ball

	player_string := fmt.tprintf(
		"Player:\n\tTranslation: [%.1f,%.1f]\n\tVelocity: [%.1f,%.1f]\n\tKick Angle: %v\n\tFlags: %v\n\tTimed Flags: %v",
		player.translation.x,
		player.translation.y,
		player.velocity.x,
		player.velocity.y,
		player.kick_angle,
		player.state_flags,
		player.timed_state_flags,
	)
	rl.DrawText(strings.clone_to_cstring(player_string), 20, 100, 16, rl.YELLOW)
	ball_string := fmt.tprintf(
		"Ball:\n\tTranslation: [%.1f,%.1f]\n\tVelocity: [%.1f,%.1f]\n\tFlags: %v\n\tTimed Flags: %v",
		ball.translation.x,
		ball.translation.y,
		ball.velocity.x,
		ball.velocity.y,
		ball.state_flags,
		ball.timed_state_flags,
	)
	rl.DrawText(strings.clone_to_cstring(ball_string), 500, 100, 16, rl.YELLOW)
}
