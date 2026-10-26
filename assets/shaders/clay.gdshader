// Soft modelling clay, for Dhulls: toon shading with a soft edge, a lumpy, finger-smoothed
// surface that catches the light, and a waxy sheen. The color runs from base_color to tip_color
// towards the ends of the limbs: the model's vertex color (red channel) says how far towards a tip
// each point is, from 0 to 1. The clay marks are laid out on the model, so they move with it.
shader_type spatial;

uniform vec4 base_color : source_color = vec4(1.0, 0.64, 0.4, 1.0);
uniform vec4 tip_color : source_color = vec4(1.0, 0.62, 0.76, 1.0);
// Share of the light that still reaches the shady side.
uniform float shade_fill : hint_range(0.0, 1.0) = 0.55;
// How soft the edge between light and shade is.
uniform float shade_softness : hint_range(0.0, 0.5) = 0.12;
// How deep the clay's lumps, smears and grain are, in meters, and how many of each per meter.
uniform float relief : hint_range(0.0, 0.01) = 0.0045;
uniform float lump_density = 28.0;
uniform float smear_density = 65.0;
uniform float grain_density = 160.0;
// How much the color darkens in the clay's dips and lightens on its bumps.
uniform float mottling : hint_range(0.0, 0.3) = 0.13;
// A soft, waxy highlight, broken up by the clay's surface.
uniform float sheen : hint_range(0.0, 1.0) = 0.45;
uniform float sheen_tightness : hint_range(2.0, 64.0) = 10.0;

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

// Height of the clay's surface above the model's, from 0 to about 1: broad lumps, thin ridges
// where it was smeared, and a fine grain.
float clay_height(vec3 p) {
	float lumps = value_noise(p * lump_density);
	float smears = 1.0 - abs(value_noise(p * smear_density + 13.0) * 2.0 - 1.0);
	float grain = value_noise(p * grain_density + 29.0);
	return lumps * 0.55 + smears * 0.3 + grain * 0.15;
}

void vertex() {
	model_position = VERTEX;
	tip_amount = COLOR.r;
}

void fragment() {
	// Tilt the normal down the slopes of the clay's surface, measured in the model.
	float step_size = 0.0015;
	float height = clay_height(model_position);
	vec3 slope = vec3(
			clay_height(model_position + vec3(step_size, 0.0, 0.0)) - height,
			clay_height(model_position + vec3(0.0, step_size, 0.0)) - height,
			clay_height(model_position + vec3(0.0, 0.0, step_size)) - height) / step_size * relief;
	vec3 view_slope = mat3(VIEW_MATRIX) * mat3(MODEL_MATRIX) * slope;
	view_slope -= NORMAL * dot(view_slope, NORMAL);
	NORMAL = normalize(NORMAL - view_slope);

	vec3 color = mix(base_color.rgb, tip_color.rgb, tip_amount);
	ALBEDO = color * (1.0 + (height - 0.5) * 2.0 * mottling);
}

void light() {
	float facing = dot(NORMAL, LIGHT);
	float lit = smoothstep(-shade_softness, shade_softness, facing);
	// A gentle falloff on top of the toon bands, so the clay's lumps show in light and shade.
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
