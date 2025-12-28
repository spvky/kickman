package main

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

player_debug :: proc() {
	player := world.player

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

	// ball_string := fmt.tprintf()

	rl.DrawText(strings.clone_to_cstring(player_string), 20, 100, 16, rl.YELLOW)
}
