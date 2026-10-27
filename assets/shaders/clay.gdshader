// Smooth modelling clay, for Dhulls: toon shading with a soft edge, a gently uneven surface and a
// waxy sheen. Each Dhull colors its own parts through the instance uniforms (see DhullColoring):
// the part's color, the color it turns towards at the tips of the nubs, and an optional pattern.
// How far towards a tip each point is comes from the model's vertex color, red channel, from 0 to
// 1. The surface and the pattern are laid out on the model, so they move with it.
shader_type spatial;

// Patterns, numbered as in DhullColoring.Pattern.
const int PATTERN_DIAMONDS = 1;
const int PATTERN_SPOTS = 2;

// Fixed instance slots 0-3, apart from the face overlay's (dhull_face.gdshader), since a head
// carries both and Godot would otherwise number each shader's slots from 0, so they'd collide.
instance uniform vec4 part_color : source_color, instance_index(0) = vec4(1.0, 0.83, 0.25, 1.0);
instance uniform vec4 tip_color : source_color, instance_index(1) = vec4(1.0, 0.55, 0.25, 1.0);
instance uniform vec4 pattern_color : source_color, instance_index(2) = vec4(0.36, 0.24, 0.8, 1.0);
instance uniform int pattern : instance_index(3) = 0;
// Size of a pattern's diamonds and spots, in meters.
uniform float diamond_size = 0.11;
uniform float spot_size = 0.06;
// Share of the light that still reaches the shady side.
uniform float shade_fill : hint_range(0.0, 1.0) = 0.55;
// How soft the edge between light and shade is.
uniform float shade_softness : hint_range(0.0, 0.5) = 0.15;
// How deep the clay's soft undulations are, in meters, and how many per meter.
uniform float relief : hint_range(0.0, 0.01) = 0.003;
uniform float undulation_density = 10.0;
// A broad, waxy highlight that wobbles over the undulations.
uniform float sheen : hint_range(0.0, 1.0) = 0.4;
uniform float sheen_tightness : hint_range(2.0, 64.0) = 8.0;

varying vec3 model_position;
varying float tip_amount;

float hash(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

float value_noise(vec3 p) {
	vec3 cell = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float result = 0.0;
	for (int i = 0; i < 8; i++) {
		vec3 corner = vec3(float(i & 1), float((i >> 1) & 1), float((i >> 2) & 1));
		vec3 weight = mix(1.0 - f, f, corner);
		result += hash(cell + corner) * weight.x * weight.y * weight.z;
	}
	return result;
}

// 1 where the pattern's second color shows, 0 elsewhere.
float pattern_mask(vec3 p) {
	if (pattern == PATTERN_DIAMONDS) {
		// Diamonds wrapped round the part's upright axis, like a harlequin's suit. The angle round
		// it times the body's rough radius gives meters.
		vec2 around = vec2(atan(p.x, p.z) * 0.14, p.y) / diamond_size;
		return mod(floor(around.x + around.y) + floor(around.x - around.y), 2.0);
	}
	if (pattern == PATTERN_SPOTS) {
		return smoothstep(0.62, 0.66, value_noise(p / spot_size + 7.0));
	}
	return 0.0;
}

void vertex() {
	model_position = VERTEX;
	tip_amount = COLOR.r;
}

void fragment() {
	// Tilt the normal down the slopes of the clay's undulations, measured in the model.
	float step_size = 0.002;
	vec3 p = model_position * undulation_density;
	float height = value_noise(p);
	vec3 slope = vec3(
			value_noise(p + vec3(step_size * undulation_density, 0.0, 0.0)) - height,
			value_noise(p + vec3(0.0, step_size * undulation_density, 0.0)) - height,
			value_noise(p + vec3(0.0, 0.0, step_size * undulation_density)) - height) / step_size * relief;
	vec3 view_slope = mat3(VIEW_MATRIX) * mat3(MODEL_MATRIX) * slope;
	view_slope -= NORMAL * dot(view_slope, NORMAL);
	NORMAL = normalize(NORMAL - view_slope);

	vec3 color = mix(part_color.rgb, pattern_color.rgb, pattern_mask(model_position));
	ALBEDO = mix(color, tip_color.rgb, tip_amount);
}

void light() {
	float facing = dot(NORMAL, LIGHT);
	float lit = smoothstep(-shade_softness, shade_softness, facing);
	// A gentle falloff on top of the toon bands, so the clay's form shows in light and shade.
	float form = 0.75 + 0.25 * (facing * 0.5 + 0.5);
	if (LIGHT_IS_DIRECTIONAL) {
		lit *= smoothstep(0.3, 0.7, ATTENUATION);
		DIFFUSE_LIGHT += mix(shade_fill, 1.0, lit) * form * LIGHT_COLOR / PI;
	} else {
		DIFFUSE_LIGHT += lit * ATTENUATION * LIGHT_COLOR / PI;
	}
	vec3 halfway = normalize(LIGHT + VIEW);
	float highlight = pow(max(dot(NORMAL, halfway), 0.0), sheen_tightness);
	SPECULAR_LIGHT += highlight * sheen * lit * ATTENUATION * LIGHT_COLOR / PI;
}
