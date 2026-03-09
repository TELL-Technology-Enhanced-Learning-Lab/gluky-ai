shader_type canvas_item;

uniform float grid_size : hint_range(20.0, 100.0) = 60.0;
uniform float scroll_speed : hint_range(0.0, 2.0) = 0.3;
uniform vec4 grid_color : source_color = vec4(0.0, 1.0, 0.8, 0.04);
uniform vec4 bg_color : source_color = vec4(0.008, 0.043, 0.078, 1.0);
uniform float vignette_strength : hint_range(0.0, 2.0) = 1.2;
uniform float glow_pulse : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 uv = UV;
	vec2 screen_uv = uv;

	// Griglia animata
	float time_offset = TIME * scroll_speed;
	vec2 grid_uv = (uv * vec2(textureSize(TEXTURE, 0))) / grid_size;
	grid_uv += vec2(time_offset * 0.5);

	vec2 grid_frac = fract(grid_uv);
	float line_x = step(0.97, grid_frac.x);
	float line_y = step(0.97, grid_frac.y);
	float grid = max(line_x, line_y);

	// Vignette radiale
	vec2 center = uv - vec2(0.5);
	float vignette = 1.0 - dot(center, center) * vignette_strength * 2.0;
	vignette = clamp(vignette, 0.0, 1.0);

	// Glow centrale pulsante
	float pulse = sin(TIME * 1.5) * 0.5 + 0.5;
	float center_glow = 1.0 - length(center) * 2.0;
	center_glow = clamp(center_glow, 0.0, 1.0);
	center_glow = pow(center_glow, 3.0) * pulse * 0.15;

	vec4 col = bg_color;
	col += grid_color * grid * vignette;
	col += vec4(0.0, 1.0, 0.8, 0.0) * center_glow;
	col.a = 1.0;

	COLOR = col;
}
