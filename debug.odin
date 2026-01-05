package main

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

player_debug :: proc() {
	player := world.player
	ball := world.ball

	player_string := fmt.tprintf(
		"Player:\n\tFacing | Running: %v | %v\n\tTranslation: [%.1f,%.1f]\n\tVelocity: [%.1f,%.1f]\n\tPlatform Velocity: [%.1f,%.1f]\n\tCombined Velocity: [%.1f,%.1f]\n\tKick Angle: %v\n\tState: %v\n\tFlags: %v\n\tTimed Flags: %v\nCam Target: %v",
		player.facing,
		player.run_direction,
		player.translation.x,
		player.translation.y,
		player.velocity.x,
		player.velocity.y,
		player.platform_velocity.x,
		player.platform_velocity.y,
		player.velocity.x + player.platform_velocity.x,
		player.velocity.y + player.platform_velocity.y,
		player.kick_angle,
		player.state,
		player.flags,
		player.timed_flags,
		world.camera.target,
	)
	rl.DrawText(strings.clone_to_cstring(player_string), 20, 100, 16, rl.YELLOW)
	ball_string := fmt.tprintf(
		"Ball:\n\tTranslation: [%.1f,%.1f]\n\tVelocity: [%.1f,%.1f]\n\tSpin: %.2f\n\tState: %v\n\tFlags: %v\n\tTimed Flags: %v",
		ball.translation.x,
		ball.translation.y,
		ball.velocity.x,
		ball.velocity.y,
		ball.spin,
		ball.state,
		ball.flags,
		ball.timed_flags,
	)
	rl.DrawText(strings.clone_to_cstring(ball_string), 800, 100, 16, rl.YELLOW)
}
