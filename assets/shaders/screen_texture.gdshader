// Film grain, faint scanlines and a vignette over the whole screen, for the moodboard's
// printed, slightly glitchy texture.
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float grain : hint_range(0.0, 0.3) = 0.07;
uniform float scanlines : hint_range(0.0, 0.3) = 0.06;
uniform float vignette : hint_range(0.0, 2.0) = 0.9;
// How many times a second the grain changes, like film frames.
uniform float grain_fps = 24.0;

void fragment() {
	vec3 color = texture(screen_texture, SCREEN_UV).rgb;
	float frame = floor(TIME * grain_fps);
	float noise = fract(sin(dot(floor(FRAGCOORD.xy) + frame * 17.0, vec2(12.9898, 78.233))) * 43758.5453);
	color += (noise - 0.5) * grain;
	color *= 1.0 - scanlines * step(0.5, fract(FRAGCOORD.y * 0.5));
	vec2 from_center = SCREEN_UV - 0.5;
	color *= 1.0 - dot(from_center, from_center) * vignette;
	COLOR = vec4(color, 1.0);
}
