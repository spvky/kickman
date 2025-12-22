package main

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

player_debug :: proc() {
	player := world.player

	player_string := fmt.tprintf(
		"Player:\n\tTranslation: [%.1f,%.1f]\n\tVelocity: [%.1f,%.1f]\n\t Flags: %v",
		player.translation.x,
		player.translation.y,
		player.velocity.x,
		player.velocity.y,
		player.state_flags,
	)

	rl.DrawText(strings.clone_to_cstring(player_string), 20, 100, 16, rl.BLACK)
}
