package main

import rl "vendor:raylib"


to_rl_color :: proc(c: Color_F, force_alpha: f32 = 0) -> rl.Color {
	return {u8(c.r), u8(c.g), u8(c.b), force_alpha == 0 ? u8(c.a) : u8(force_alpha)}
}
