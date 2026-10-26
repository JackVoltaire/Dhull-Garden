// Toon shading for the 3D world, drawn like the moodboard: a hard edge between light and shade,
// scratchy ink hatching on the shady side, and crayon streaks across the whole surface. The marks
// are laid out in world space, so they stick to surfaces instead of the screen.
shader_type spatial;
render_mode specular_disabled;

uniform vec4 albedo : source_color = vec4(0.5, 0.5, 0.5, 1.0);
// Share of the sunlight that still reaches the shady side. Hatching is drawn by taking it away,
// so at 0 there's nothing to hatch.
uniform float shade_fill : hint_range(0.0, 1.0) = 0.3;
// Hatching lines per meter.
uniform float hatch_density : hint_range(0.5, 20.0) = 6.0;
// Thickness of each hatching line, as a fraction of the gap between lines.
uniform float hatch_width : hint_range(0.0, 1.0) = 0.35;
// How far the lines wander sideways, as a fraction of the gap between lines.
uniform float hatch_wobble : hint_range(0.0, 1.0) = 0.5;
// How much the crayon streaks lighten and darken the surface.
uniform float crayon_strength : hint_range(0.0, 1.0) = 0.3;
// Crayon streaks per meter, across their length.
uniform float crayon_density : hint_range(0.1, 20.0) = 4.0;

varying float hatch;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
			mix(hash(cell), hash(cell + vec2(1.0, 0.0)), f.x),
			mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0, 1.0)), f.x),
			f.y);
}

// Projects the surface onto the world plane it faces most, so marks keep their size on any slope.
vec2 surface_coords(vec3 world_position, vec3 world_normal) {
	vec3 facing = abs(world_normal);
	if (facing.y >= facing.x && facing.y >= facing.z) {
		return world_position.xz;
	}
	if (facing.x >= facing.z) {
		return world_position.zy;
	}
	return world_position.xy;
}

void fragment() {
	vec3 world_position = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 world_normal = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec2 coords = surface_coords(world_position, world_normal);
	vec2 stroke_direction = normalize(vec2(1.0, 0.6));
	float along = dot(coords, stroke_direction);
	float across = dot(coords, vec2(-stroke_direction.y, stroke_direction.x));

	// Hatching: diagonal lines that wander a little and break into strokes of uneven length.
	float line_coord = across * hatch_density + (value_noise(coords * 1.5) - 0.5) * hatch_wobble * 2.0;
	float line_index = floor(line_coord);
	float stroke = step(fract(along * hatch_density * 0.2 + hash(vec2(line_index, 3.7)) * 7.0), 0.8);
	float distance_from_line = abs(fract(line_coord) - 0.5) * 2.0;
	float blur = fwidth(line_coord);
	float line = 1.0 - smoothstep(hatch_width - blur, hatch_width + blur, distance_from_line);
	// Far away the lines crowd into a few pixels and shimmer, so they fade out instead.
	hatch = line * stroke * (1.0 - smoothstep(0.3, 0.6, blur));

	// Crayon: streaks stretched along the strokes, lighter and darker than the base color.
	float streaks = value_noise(vec2(along * crayon_density * 0.15, across * crayon_density));
	ALBEDO = albedo.rgb * (1.0 + (streaks - 0.5) * 2.0 * crayon_strength);
}

void light() {
	float facing = dot(NORMAL, LIGHT);
	if (LIGHT_IS_DIRECTIONAL) {
		// A hard edge between light and shade, cast shadows included.
		float lit = step(0.0, facing) * step(0.5, ATTENUATION);
		float shade = shade_fill * (1.0 - hatch);
		DIFFUSE_LIGHT += mix(shade, 1.0, lit) * LIGHT_COLOR / PI;
	} else {
		DIFFUSE_LIGHT += step(0.0, facing) * ATTENUATION * LIGHT_COLOR / PI;
	}
}
