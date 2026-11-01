// Characters cel-shaded like anime: a crisp edge between light and shade, the shade a deeper,
// cooler take on each part's own color, as anime paints it (warm and rosy on skin), a thin rim of
// light along the lit side's outline, and on hair a band of highlight round the crown. Detail is
// painted over parts in crunchy pixels, as House of Decay paints its textures: strands through
// hair, folds in cloth. The tips' color is stepped and dithered rather than smooth, like a PS1
// texture.
// Heads turn towards the camera (see head_turn.gdshaderinc). Each character colors its own parts
// through the instance uniforms (see DhullColoring): the part's color, the color it turns towards
// at the tips, and an optional pattern. How far towards a tip each point is comes from the
// model's vertex color, red channel.
// Characters have no ink lines round them, as House of Decay's have none: they mark themselves in
// the normal-roughness buffer with CHARACTER_ROUGHNESS, and the world's ink lines
// (ink_outlines.gdshader) leave out whatever has it. With no specular, the roughness changes
// nothing else about how they look.
shader_type spatial;

#include "res://assets/shaders/head_turn.gdshaderinc"

const float CHARACTER_ROUGHNESS = 0.3;
// Patterns, numbered as in DhullColoring.Pattern.
const int PATTERN_DIAMONDS = 1;
const int PATTERN_SPOTS = 2;
const int PATTERN_STRIPES = 3;
// A 4x4 Bayer matrix: the threshold pattern PS1 games dithered with.
const float BAYER[16] = {0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0};

// Fixed instance slots 0-3, apart from the face overlay's (dhull_face.gdshader), since a head
// carries both and Godot would otherwise number each shader's slots from 0, so they'd collide.
instance uniform vec4 part_color : source_color, instance_index(0) = vec4(1.0, 0.83, 0.25, 1.0);
instance uniform vec4 tip_color : source_color, instance_index(1) = vec4(1.0, 0.55, 0.25, 1.0);
instance uniform vec4 pattern_color : source_color, instance_index(2) = vec4(0.36, 0.24, 0.8, 1.0);
instance uniform int pattern : instance_index(3) = 0;
// How bright the highlight round the crown is, from 0 (none, on anything but hair) to 1. Slot 12,
// past the head turn's.
instance uniform float sheen : instance_index(12) = 0.0;
// The detail painted over the part, a CharacterDetail.Kind. Slot 13.
instance uniform int detail : instance_index(13) = 0;
// Size of a pattern's diamonds and spots, and how wide each stripe is, in meters.
uniform float diamond_size = 0.11;
uniform float spot_size = 0.06;
uniform float stripe_size = 0.045;
// The share of the light, in each color, that still reaches the shady side: under 1 and bluer
// than the light, for cool anime shade.
uniform vec3 shade_color : source_color = vec3(0.66, 0.6, 0.74);
// How far the shade also takes on the part's own color, from 0 to 1, so it's a deeper, richer
// version of it rather than the same tint over everything: rosy on skin, orange on yellow.
uniform float shade_own_color : hint_range(0.0, 1.0) = 0.75;
// Where the shade starts, as how squarely a surface faces the light, from -1 (facing away) to 1;
// and how soft its edge is.
uniform float shade_edge : hint_range(-1.0, 1.0) = 0.0;
// Where the shade starts on heads: later than elsewhere, so a face is lit unless the light is
// well behind it, as anime keeps faces in the light.
uniform float head_shade_edge : hint_range(-1.0, 1.0) = -0.45;
uniform float shade_softness : hint_range(0.0, 0.5) = 0.02;
// The rim of light: how far in from the outline it reaches, as how far a surface turns from the
// camera, from 0 to 1, and how bright it is.
uniform float rim_width : hint_range(0.0, 1.0) = 0.25;
uniform float rim_strength : hint_range(0.0, 1.0) = 0.35;
// The highlight round the crown: how high up the head it runs, from where to where, as the sine
// of the angle above the head's middle; how many pointed strands its lower edge breaks into, and
// how far the longest reach down; how squarely the hair must face the camera for it to show,
// from 0 to 1, so it's an arc on the near side, as anime draws it, not a ring all round; and how
// far it pales the hair towards white.
uniform vec2 sheen_height = vec2(0.54, 0.62);
uniform int sheen_strands = 12;
uniform float sheen_strand_length = 0.14;
uniform float sheen_facing : hint_range(0.0, 1.0) = 0.45;
uniform float sheen_whiteness : hint_range(0.0, 1.0) = 0.35;
// The detail: a tile per CharacterDetail.Kind past NONE, stacked top to bottom, in grey (mid grey
// leaves the part's color as it is, darker darkens it, lighter lightens it); how many there are;
// how far each tile reaches over a part, in meters; and how strongly it shows, from 0 to 1.
uniform sampler2D detail_tiles : filter_nearest, repeat_enable;
uniform int detail_kinds = 2;
uniform float detail_size = 0.5;
uniform float detail_strength : hint_range(0.0, 1.0) = 1.0;
// How many steps the tip color comes in.
uniform int tip_bands : hint_range(2, 16) = 4;
// Size of a dither dot, in screen pixels on a screen 720 pixels tall; it scales with resolution.
uniform float dither_pixel = 2.0;

varying vec3 model_position;
varying float tip_amount;
// 1 on a head, 0 elsewhere.
varying float on_head;

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

// 1 where the highlight round the crown lies on hair at [p], in the head's model space, 0
// elsewhere: a band at a set height, its lower edge broken into pointed strands of uneven length.
float sheen_band(vec3 p) {
	vec3 from_middle = normalize(p);
	float strands_round = atan(from_middle.x, from_middle.z) * float(sheen_strands) / TAU;
	float point = 1.0 - abs(fract(strands_round) - 0.5) * 2.0;
	float length = mix(0.4, 1.0, hash(vec3(floor(strands_round), 0.0, 0.0)));
	float lowest = sheen_height.x - point * length * sheen_strand_length;
	return step(lowest, from_middle.y) * step(from_middle.y, sheen_height.y);
}

// What the detail does to the part's color at [p], in its model space: 1 leaves it as it is,
// less darkens it, more lightens it. The tile is wrapped round the part's upright axis, as far
// round as the part's surface goes there, and repeated down it, so the models need no UVs.
float detail_shade(vec3 p) {
	if (detail == 0) {
		return 1.0;
	}
	vec2 over_part = vec2(atan(p.x, p.z) * length(p.xz), -p.y) / detail_size;
	vec2 in_tile = vec2(fract(over_part.x), (fract(over_part.y) + float(detail - 1)) / float(detail_kinds));
	return mix(1.0, texture(detail_tiles, in_tile).r * 2.0, detail_strength);
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
	if (pattern == PATTERN_STRIPES) {
		// Bands across the part, like a striped sleeve, so they swing with it.
		return mod(floor(p.y / stripe_size), 2.0);
	}
	return 0.0;
}

void vertex() {
	model_position = VERTEX;
	tip_amount = COLOR.r;
	on_head = is_head() ? 1.0 : 0.0;
	turn_head(VERTEX, NORMAL, MODEL_MATRIX, MAIN_CAM_INV_VIEW_MATRIX);
}

void fragment() {
	float threshold = dither(FRAGCOORD.xy, VIEWPORT_SIZE);
	vec3 color = mix(part_color.rgb, pattern_color.rgb, pattern_mask(model_position));
	ALBEDO = mix(color, tip_color.rgb, banded(tip_amount, tip_bands, threshold));
	ALBEDO *= detail_shade(model_position);
	SPECULAR = 0.0;
	ROUGHNESS = CHARACTER_ROUGHNESS;
}

void light() {
	float facing = dot(NORMAL, LIGHT);
	float edge = mix(shade_edge, head_shade_edge, on_head);
	float lit = smoothstep(edge - shade_softness, edge + shade_softness, facing);
	if (LIGHT_IS_DIRECTIONAL) {
		// Cast shadows are shade too, with the same crisp edge; but not on heads, where the hair's
		// shadow would put the whole face in shade. As in anime, a head is shaded by how it faces
		// the light alone.
		float shadow = smoothstep(0.5 - shade_softness, 0.5 + shade_softness, ATTENUATION);
		lit *= max(shadow, on_head);
		float rim = step(1.0 - rim_width, 1.0 - dot(NORMAL, VIEW)) * rim_strength * lit;
		vec3 shade = shade_color * mix(vec3(1.0), ALBEDO, shade_own_color);
		DIFFUSE_LIGHT += (mix(shade, vec3(1.0), lit) + rim) * LIGHT_COLOR / PI;
		// The highlight brightens the hair's own color and pales it towards white.
		float facing_camera = smoothstep(sheen_facing - 0.1, sheen_facing + 0.1, dot(NORMAL, VIEW));
		float highlight = sheen * sheen_band(model_position) * facing_camera * lit;
		DIFFUSE_LIGHT += highlight * LIGHT_COLOR / PI;
		SPECULAR_LIGHT += highlight * sheen_whiteness * LIGHT_COLOR / PI;
	} else {
		DIFFUSE_LIGHT += lit * ATTENUATION * LIGHT_COLOR / PI;
	}
}
