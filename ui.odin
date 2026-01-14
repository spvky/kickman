package main

import "core:math"
import rl "vendor:raylib"

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
	rl.DrawPolyLines({s_height / 2, s_width / 2}, 5, 20, 0, rl.RED)
	rl.DrawPolyLinesEx(
		{s_width, s_height} / 2,
		10,
		50,
		-f32(math.sin(rl.GetTime() / 10)) * 300,
		3,
		rl.RED,
	)
	rl.DrawPolyLinesEx(
		{s_width, s_height} / 2,
		5,
		50,
		f32(math.sin(rl.GetTime() / 10)) * 300,
		3,
		rl.RED,
	)
	font_size: i32 = 18
	text_width := rl.MeasureText("Cave of Enlightenment", font_size)
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
