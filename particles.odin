package main

import "core:log"
import "core:math"
import "core:math/rand"
import rl "vendor:raylib"

Particle_Emitter :: struct($N: int) {
	particles: [N]Particle,
	color:     rl.Color,
	display:   Particle_Emitter_Display,
	effects:   bit_set[Particle_Effect;u8],
	lifetime:  f32,
	gravity:   Vec2,
}

Particle_Effect :: enum u8 {
	Fade,
}

Particle :: struct {
	position: Vec2,
	velocity: Vec2,
	lifetime: f32,
	display:  Particle_Display,
	active:   bool,
}

Particle_Emitter_Circle :: struct {
	min_radius: f32,
	max_radius: f32,
}

Particle_Emitter_Rectangle :: struct {
	extents: Vec2,
}

Particle_Emitter_Texture :: struct {
	texture_ptr: ^rl.Texture,
	source:      rl.Rectangle,
	extents:     Vec2,
}

Particle_Emitter_Display :: union {
	Particle_Emitter_Circle,
	Particle_Emitter_Rectangle,
	Particle_Emitter_Texture,
}

Particle_Circle :: struct {
	radius: f32,
}

Particle_Texture :: struct {
	extents: Vec2,
}

Particle_Rectangle :: struct {
	extents: Vec2,
}

Particle_Display :: union {
	Particle_Circle,
	Particle_Rectangle,
	Particle_Texture,
}

first_free :: proc(pe: ^Particle_Emitter($T)) -> (index: int) {
	for p, i in pe.particles {
		if !p.active {
			index = i
			return
		}
	}
	index = -1
	return
}

new_particle :: proc(pe: ^Particle_Emitter($T), position, velocity: Vec2) {
	free := first_free(pe)
	if free != -1 {
		particle := &pe.particles[free]
		particle.position = position
		particle.velocity = velocity
		particle.lifetime = pe.lifetime
		particle.active = true
		switch d in pe.display {
		case Particle_Emitter_Circle:
			r := rand.float32()
			radius := d.min_radius + r * (d.max_radius - d.min_radius)
			particle.display = Particle_Circle{radius}
		case Particle_Emitter_Rectangle:
		case Particle_Emitter_Texture:
		}
	}
}

update_particles :: proc(pe: ^Particle_Emitter($T), delta: f32) {
	for &p in pe.particles {
		if p.active {
			p.lifetime -= delta
			if p.lifetime <= 0 {
				p.lifetime = 0
				p.active = false
			}
			p.velocity += pe.gravity * delta
			p.position += p.velocity * delta
		}
	}
}

clear_particles :: proc(pe: ^Particle_Emitter($T)) {
	for &p in pe.particles {
		p.active = false
	}
}

render_particles :: proc(pe: ^Particle_Emitter($T)) {
	color := pe.color
	for p in pe.particles {
		if p.active {
			if .Fade in pe.effects {
				alpha := (p.lifetime / pe.lifetime) * 255
				color.a = u8(alpha)
			}
			switch s in pe.display {
			case Particle_Emitter_Circle:
				d := p.display.(Particle_Circle)
				rl.DrawCircleV(p.position, d.radius, color)
			case Particle_Emitter_Rectangle:
				rl.DrawRectangleV(p.position, s.extents, color)
			case Particle_Emitter_Texture:
				d := p.display.(Particle_Texture)
				rl.DrawTexturePro(
					s.texture_ptr^,
					s.source,
					{p.position.x, p.position.y, d.extents.x, d.extents.y},
					VEC_0,
					0,
					color,
				)
			}
		}
	}
}

make_dust :: proc(count: int, origin: Vec2, min_angle, max_angle: f32) {
	for i in 0 ..< count {
		r := rand.float32()
		angle := min_angle + r * (max_angle - min_angle)
		velocity := Vec2{math.cos(angle), math.sin(angle)} * 35
		new_particle(&world.dust_particles, origin, velocity)
	}
}

clear_dust :: proc() {
	clear_particles(&world.dust_particles)
}
