// Characters shaded like a PS1-era game, as in House of Decay: flat-shaded facets, light in a few
// coarse bands with ordered dithering between them, and the nub tips' color stepped and dithered
// rather than smooth. Each character colors its own parts through the instance uniforms (see
// DhullColoring): the part's color, the color it turns towards at the tips, and an optional
// pattern. How far towards a tip each point is comes from the model's vertex color, red channel.
shader_type spatial;

// Patterns, numbered as in DhullColoring.Pattern.
const int PATTERN_DIAMONDS = 1;
const int PATTERN_SPOTS = 2;
// A 4x4 Bayer matrix: the threshold pattern PS1 games dithered with.
const float BAYER[16] = {0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0};

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
uniform float shade_fill : hint_range(0.0, 1.0) = 0.5;
// How many steps light falls off in, and how many steps the tip color comes in.
uniform int light_bands : hint_range(2, 16) = 4;
uniform int tip_bands : hint_range(2, 16) = 4;
// Size of a dither dot, in screen pixels on a screen 720 pixels tall; it scales with resolution.
uniform float dither_pixel = 2.0;

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

// The dither threshold at a screen pixel, from 0 to 1.
float dither(vec2 frag_coord, vec2 viewport_size) {
	ivec2 cell = ivec2(frag_coord / (dither_pixel * viewport_size.y / 720.0)) % 4;
	return (BAYER[cell.y * 4 + cell.x] + 0.5) / 16.0;
}

// A value from 0 to 1 snapped to a few steps, dithered where it falls between two.
float banded(float value, int bands, float threshold) {
	float steps = float(bands - 1);
	return clamp(floor(value * steps + threshold) / steps, 0.0, 1.0);
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
		return step(0.64, value_noise(p / spot_size + 7.0));
	}
	return 0.0;
}

void vertex() {
	model_position = VERTEX;
	tip_amount = COLOR.r;
}

void fragment() {
	float threshold = dither(FRAGCOORD.xy, VIEWPORT_SIZE);
	vec3 color = mix(part_color.rgb, pattern_color.rgb, pattern_mask(model_position));
	ALBEDO = mix(color, tip_color.rgb, banded(tip_amount, tip_bands, threshold));
}

void light() {
	float threshold = dither(FRAGCOORD.xy, VIEWPORT_SIZE);
	// Half-Lambert: light wraps softly round the form before it's cut into bands.
	float wrapped = dot(NORMAL, LIGHT) * 0.5 + 0.5;
	float lit = banded(wrapped * wrapped, light_bands, threshold);
	if (LIGHT_IS_DIRECTIONAL) {
		float shadow = banded(ATTENUATION, 2, threshold);
		DIFFUSE_LIGHT += mix(shade_fill, 1.0, lit * shadow) * LIGHT_COLOR / PI;
	} else {
		DIFFUSE_LIGHT += lit * ATTENUATION * LIGHT_COLOR / PI;
	}
}
