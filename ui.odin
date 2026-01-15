package main

import "core:fmt"
import "core:math"
import "core:strings"
import rl "vendor:raylib"

Sigil :: struct {
	rotation_timer:  f32,
	target_rotation: f32,
	rotation:        f32,
	color:           [3]f32,
	target_color:    [3]f32,
}

RED: [3]f32 : {1, 0, 0}
GREEN: [3]f32 : {0, 1, 0}
BLUE: [3]f32 : {0, 0, 1}

sigil := Sigil {
	color           = RED,
	target_color    = RED,
	rotation        = 30,
	target_rotation = 30,
}

draw_text :: proc() {
	rl.DrawTextEx(assets.font, "Hello Dungeon", {200, 100}, 24, 1, rl.WHITE)
}

level_banner :: proc() {
	banner_color := rl.Color{0, 0, 0, 200}
	s_width := f32(SCREEN_WIDTH)
	s_height := f32(SCREEN_HEIGHT)
	origin := Vec2{0, s_height / 3}
	extents := Vec2{s_width, s_height / 3}
	rl.DrawRectangleV(origin, extents, banner_color)
	font_size: i32 = 18
	text_width := rl.MeasureText("Cave of Enlightenment", font_size)
	draw_sigil({25, 20}, 40)
	rl.DrawTextPro(
		assets.font,
		"Cave of Enlightenment",
		{s_width / 2 - f32(text_width), s_height / 2 - f32(font_size) / 2},
		{0, 0},
		0,
		f32(font_size),
		0,
		rl.WHITE,
	)
}

draw_sigil :: proc(origin: Vec2, radius: f32) {
	delta := rl.GetFrameTime()
	sigil.rotation_timer += delta
	if sigil.rotation_timer >= 2 {
		sigil.target_rotation += 120.0
		sigil.rotation_timer = 0

		switch sigil.target_color {
		case RED:
			sigil.target_color = GREEN
		case GREEN:
			sigil.target_color = BLUE
		case BLUE:
			sigil.target_color = RED
		}
	}
	sigil.rotation = math.lerp(sigil.rotation, sigil.target_rotation, delta * 10)
	sigil.color = math.lerp(sigil.color, sigil.target_color, delta * 10)

	rot_string := fmt.tprintf("Rot: %.2f", sigil.target_rotation)
	true_color := rl.Color {
		u8(sigil.color.r * 255),
		u8(sigil.color.g * 255),
		u8(sigil.color.b * 255),
		255,
	}

	rl.DrawPolyLinesEx(
		origin,
		10,
		radius, //50
		-sigil.rotation,
		3,
		true_color,
	)
	rl.DrawPolyLinesEx(
		origin,
		5,
		radius * 0.98, //48,
		sigil.rotation,
		3,
		true_color,
	)
	rl.DrawPolyLinesEx(
		origin,
		20,
		radius * 0.8, //40
		sigil.rotation,
		3,
		true_color,
	)
	rl.DrawPolyLinesEx(origin, 3, radius * 0.8, -sigil.rotation, 5, true_color)
}
