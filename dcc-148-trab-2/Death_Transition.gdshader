shader_type canvas_item;

uniform vec2 center = vec2(0.5, 0.5);
uniform float radius = 2.5;
uniform float softness = 0.02;

void fragment() {
	vec2 screen_size = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 d = (SCREEN_UV - center) * vec2(screen_size.x / screen_size.y, 1.0);
	float a = smoothstep(radius, radius + softness, length(d));
	COLOR = vec4(0.0, 0.0, 0.0, a);
}