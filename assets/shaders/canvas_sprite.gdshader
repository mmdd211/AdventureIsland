shader_type canvas_item;

uniform vec4 flash_color : source_color = vec4(3.0, 3.0, 3.0, 1.0);
uniform float flash_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 0.0);
uniform float outline_width : hint_range(0.0, 8.0) = 0.0;

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	float alpha_sum = 0.0;
	float nearest = 1.0;
	for (int y = -1; y <= 1; y += 1) {
		for (int x = -1; x <= 1; x += 1) {
			vec2 offset = vec2(float(x), float(y)) * outline_width * TEXTURE_PIXEL_SIZE;
			float sample_alpha = texture(TEXTURE, UV + offset).a;
			alpha_sum += sample_alpha;
			nearest = min(nearest, sample_alpha);
		}
	}
	float outline_alpha = clamp(alpha_sum - color.a * 9.0, 0.0, 1.0);
	vec4 outlined = mix(color, outline_color, outline_alpha * outline_color.a);
	vec4 flashed = mix(outlined, flash_color, flash_strength);
	COLOR = flashed;
}
