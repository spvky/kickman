package main

import "core:fmt"
import "core:log"
import "core:math"
import "core:strings"
import "tags"
import rl "vendor:raylib"

Ui :: struct {
	visible:            [Ui_Element]bool,
	juice:              [Ui_Element]f32,
	region_display_tag: tags.Region_Tag,
}

Ui_Element :: enum {
	Region_Display,
}

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

init_ui :: proc() {
	subscribe_event(.Region_Change, region_change_listener)
}

update_ui :: proc(delta: f32) {
	manage_ui_juice_values(delta)
}

ui_set_element_values :: proc(element: Ui_Element, visible: bool, juice: f32) {
	ui.visible[element] = visible
	ui.juice[element] = juice
}

manage_ui_juice_values :: proc(delta: f32) {
	if ui.visible[.Region_Display] {
		ui.juice[.Region_Display] -= delta
		if ui.juice[.Region_Display] <= 0 {
			ui.juice[.Region_Display] = 0
			ui.visible[.Region_Display] = false
		}
	}
}

draw_text :: proc() {
	rl.DrawTextEx(assets.font, "Hello Dungeon", {200, 100}, 24, 1, rl.WHITE)
}

draw_region_banner :: proc() {
	if ui.visible[.Region_Display] {
		banner_color := rl.Color{0, 0, 0, 200}
		region_string: string

		switch ui.region_display_tag {
		case .tutorial:
			region_string = "Cave of Enlightenment"
		case .field:
			region_string = "Snowy Ass Field"
		}

		region_c_string := strings.clone_to_cstring(
			region_string,
			allocator = context.temp_allocator,
		)

		s_width := f32(SCREEN_WIDTH)
		s_height := f32(SCREEN_HEIGHT)
		origin := Vec2{0, s_height / 3}
		extents := Vec2{s_width, s_height / 3}
		font_size: i32 = 18
		text_width := rl.MeasureText(region_c_string, font_size)
		text_position: Vec2 = {s_width / 2 - f32(text_width), s_height / 2 - f32(font_size) / 2}
		if ui.juice[.Region_Display] <= 1 {
			offset: f32 = math.lerp(f32(-1000.0), f32(0.0), ui.juice[.Region_Display])
			text_position += VEC_X * offset
			origin += VEC_X * offset
		}
		rl.DrawRectangleV(origin, extents, banner_color)
		rl.DrawTextPro(
			assets.font,
			region_c_string,
			text_position,
			{0, 0},
			0,
			f32(font_size),
			0,
			rl.WHITE,
		)
	}
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

region_change_listener :: proc(event: Event) {
	if event.type == .Region_Change {
		payload := event.payload.(Event_Region_Change)
		log.debugf("New Region: %v", payload.new_region)
		ui.region_display_tag = payload.new_region
		ui_set_element_values(.Region_Display, true, 3)
	}
}
