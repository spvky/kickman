package main

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

player_debug :: proc() {
	player := world.player

	player_string := fmt.tprintf(
		"Player:\n\tTranslation: [%.1f,%.1f]\n\tVelocity: [%.1f,%.1f]\n\tIgnore Ball: %.2f\n\tFlags: %v",
		player.translation.x,
		player.translation.y,
		player.velocity.x,
		player.velocity.y,
		player.ignore_ball,
		player.state_flags,
	)

	// ball_string := fmt.tprintf()

	rl.DrawText(strings.clone_to_cstring(player_string), 20, 100, 16, rl.RED)
}
