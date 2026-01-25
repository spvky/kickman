package main

import "core:log"
import "core:math"
import "core:math/rand"
import rl "vendor:raylib"

Particle_System :: struct {
	fire_particles: Particle_Emitter(200),
	dust_particles: Particle_Emitter(50),
}

init_particle_system :: proc() {
	particles := &world.particles

	particles.dust_particles = Particle_Emitter(50) {
		color         = {255, 255, 255, 100},
		gravity       = {0, -10},
		display       = Particle_Emitter_Circle{0.5, 1.5},
		lifetime      = 0.5,
		effects       = {.Fade},
		particle_type = .Dust,
	}
	particles.fire_particles = Particle_Emitter(200) {
		color         = {255, 255, 255, 100},
		gravity       = {0, -10},
		display       = Particle_Emitter_Circle{0.5, 4},
		lifetime      = 1,
		effects       = {.Fade},
		particle_type = .Fire,
	}
}

update_particles :: proc(delta: f32) {
	particles := &world.particles
	update_particle_emitter(&particles.dust_particles, delta)
	update_particle_emitter(&particles.fire_particles, delta)
}

Particle_Emitter :: struct($N: int) {
	particles:     [N]Particle,
	particle_type: Particle_Type,
	color:         rl.Color,
	display:       Particle_Emitter_Display,
	effects:       bit_set[Particle_Effect;u8],
	lifetime:      f32,
	gravity:       Vec2,
}


Particle_Effect :: enum u8 {
	Fade,
}

Particle :: struct {
	origin:       Vec2,
	position:     Vec2,
	velocity:     Vec2,
	lifetime:     f32,
	display:      Particle_Display,
	active:       bool,
	color:        Color_F,
	target_color: Color_F,
}

Particle_Type :: enum {
	Dust,
	Sparks,
	Fire,
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
		particle.origin = position
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

update_particle_emitter :: proc(pe: ^Particle_Emitter($T), delta: f32) {
	ball := &world.ball
	for &p in pe.particles {
		if p.active {
			p.lifetime -= delta
			if p.lifetime <= 0 {
				p.lifetime = 0
				p.active = false
			}
			switch pe.particle_type {
			case .Dust, .Sparks:
				p.velocity += pe.gravity * delta
				p.position += p.velocity * delta
			case .Fire:
				log.debug("Updating fire particles")
				pd := pe.display.(Particle_Emitter_Circle)
				d := &p.display.(Particle_Circle)
				p.position.y -= delta * 10
				p.position.x = (math.sin(p.lifetime * 10) * 4)
				d.radius = math.lerp(pd.min_radius, pd.max_radius, p.lifetime)
				switch {
				case p.lifetime <= 0.2:
					p.target_color = {255, 255, 255, 50}
				case p.lifetime > 0.2 && p.lifetime <= 0.6:
					p.target_color = {220, 141, 49, 255}
				case p.lifetime > 0.6:
					p.target_color = {255, 231, 23, 255}
				}
				p.color = math.lerp(p.color, p.target_color, delta * 4)
			}
		}
	}
}

clear_particle_emitter :: proc(pe: ^Particle_Emitter($T)) {
	for &p in pe.particles {
		p.active = false
	}
}

render_particle_emitter :: proc(pe: ^Particle_Emitter($T)) {
	ball := &world.ball
	color := pe.color
	for p in pe.particles {
		if p.active {
			position := p.position
			if .Fade in pe.effects {
				alpha := (p.lifetime / pe.lifetime) * 255
				color.a = u8(alpha)
			}
			if pe.particle_type == .Fire {
				color = {u8(p.color.r), u8(p.color.g), u8(p.color.b), u8(p.color.a)}
				position = p.position + ball.translation
			}
			switch s in pe.display {
			case Particle_Emitter_Circle:
				d := p.display.(Particle_Circle)
				rl.DrawCircleV(position, d.radius, color)
			case Particle_Emitter_Rectangle:
				rl.DrawRectangleV(position, s.extents, color)
			case Particle_Emitter_Texture:
				d := p.display.(Particle_Texture)
				rl.DrawTexturePro(
					s.texture_ptr^,
					s.source,
					{p.position.x, position.y, d.extents.x, d.extents.y},
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
		velocity := Vec2{math.cos(angle), math.sin(angle)} * 100
		new_particle(&world.particles.dust_particles, origin, velocity)
	}
}

make_fire :: proc(count: int, origin: Vec2, radius: f32) {
	r := radius * rand.float32()
	angle := r * 2 * f32(math.PI)
	po: Vec2
	po.x = origin.x + r * math.cos(angle)
	po.y = origin.y + r * math.sin(angle)
	new_particle(&world.particles.fire_particles, po, VEC_0)

}

make_sparks :: proc(count: int, origin: Vec2, min_angle, max_angle: f32, direction: f32) {
	for i in 0 ..< count {
		r := rand.float32()
		angle := min_angle + r * (max_angle - min_angle)
		velocity := Vec2{math.cos(angle), math.sin(angle)} * 20
		velocity.x += direction * 80
		new_particle(&world.particles.dust_particles, origin, velocity)
	}
}

clear_dust :: proc() {
	clear_particle_emitter(&world.particles.dust_particles)
}
