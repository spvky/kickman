package main

import "core:math"

TILE_SIZE: f32 : 8
// How far can the player jump horizontally (in pixels)
JUMP_DISTANCE: f32 : 7 * TILE_SIZE
// How far can the player jump horizontally while_dashing
DASH_JUMP_DISTANCE: f32 : 14 * TILE_SIZE
// How long to reach jump peak (in seconds)
TIME_TO_PEAK: f32 : 0.3
// How long to reach height we jumped from (in seconds)
TIME_TO_DESCENT: f32 : 0.28
// How many pixels high is a full jump
JUMP_HEIGHT: f32 : 3.5 * TILE_SIZE
// How long to reach the top of our bounce arc (in seconds)
BOUNCE_TIME_TO_PEAK: f32 : 0.4
// How long to reach height we bounced from (in seconds)
BOUNCE_TIME_TO_DESCENT: f32 : 0.3
// How many pixels high is a full bounce
BOUNCE_HEIGHT: f32 : 4 * TILE_SIZE
// How many tiles per second the ball can roll at max speed
MAX_SISYPHUS_ROLL_SPEED: f32 : TILE_SIZE * 40
// How many seconds from a standstill does it take to reach max roll speed
TIME_TO_MAX_ROLL_SPEED: f32 : 5

MAX_CHAIN_LENGTH: f32 : TILE_SIZE * 20

run_speed := calculate_ground_speed()
dash_speed := calculate_dash_speed()
jump_speed := calulate_jump_speed()
rising_gravity := calculate_rising_gravity()
falling_gravity := calculate_falling_gravity()
bounce_speed := calculate_bounce_speed()
bounce_rising_gravity := calculate_bounce_rising_gravity()
bounce_falling_gravity := calculate_bounce_falling_gravity()
roll_acceleration := calculate_roll_acceleration()
roll_pivot_acceleration := calculate_roll_pivot_acceleration()

// Jumping
calulate_jump_speed :: proc "c" () -> f32 {
	return (-2 * JUMP_HEIGHT) / TIME_TO_PEAK
}

calculate_rising_gravity :: proc "c" () -> f32 {
	return (2 * JUMP_HEIGHT) / math.pow(TIME_TO_PEAK, 2)
}

calculate_falling_gravity :: proc "c" () -> f32 {
	return (2 * JUMP_HEIGHT) / math.pow(TIME_TO_DESCENT, 2)
}

// Bouncing
calculate_bounce_speed :: proc "c" () -> f32 {
	return (-2 * BOUNCE_HEIGHT) / BOUNCE_TIME_TO_PEAK
}

calculate_bounce_rising_gravity :: proc "c" () -> f32 {
	return (2 * BOUNCE_HEIGHT) / math.pow(BOUNCE_TIME_TO_PEAK, 2)
}

calculate_bounce_falling_gravity :: proc "c" () -> f32 {
	return (2 * BOUNCE_HEIGHT) / math.pow(BOUNCE_TIME_TO_DESCENT, 2)
}
// Lateral Movement
calculate_ground_speed :: proc "c" () -> f32 {
	return JUMP_DISTANCE / (TIME_TO_PEAK + TIME_TO_DESCENT)
}

calculate_dash_speed :: proc "c" () -> f32 {
	return DASH_JUMP_DISTANCE / (TIME_TO_PEAK + TIME_TO_DESCENT)
}
// Sisyphus
calculate_roll_acceleration :: proc "c" () -> f32 {
	return MAX_SISYPHUS_ROLL_SPEED / TIME_TO_MAX_ROLL_SPEED
}

calculate_roll_pivot_acceleration :: proc "c" () -> f32 {
	return MAX_SISYPHUS_ROLL_SPEED / (TIME_TO_MAX_ROLL_SPEED / 2)
}

// Colors

COLOR_WHITE: Color_F : {255, 255, 255, 255}
COLOR_SIGIL_WHITE: Color_F : {255, 255, 255, 100}
COLOR_REV: Color_F : {203, 178, 112, 255}
COLOR_RECALL: Color_F : {165, 134, 236, 255}
COLOR_CAPTURED: Color_F : {20, 105, 152, 255}
COLOR_CANNON: Color_F : {205, 217, 55, 255}
