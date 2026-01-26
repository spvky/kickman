package main

import rl "vendor:raylib"


to_rl_color :: proc(c: Color_F) -> rl.Color {
	return {u8(c.r), u8(c.g), u8(c.b), u8(c.a)}
}
