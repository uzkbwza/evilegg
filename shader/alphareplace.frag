uniform sampler2D replace_texture; 
uniform sampler2D input_texture; 
uniform float old_alpha;

uniform vec4 mask_color;
uniform vec2 viewport_size;
uniform vec2 canvas_size;
uniform vec2 canvas_pos;

const float TOLERANCE = 0.01;

bool is_approx_equal(vec4 a, vec4 b) {
	return abs(a.r - b.r) < TOLERANCE && abs(a.g - b.g) < TOLERANCE && abs(a.b - b.b) < TOLERANCE;
}

vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
	vec2 uv = texture_coords;

	vec4 texel = Texel(input_texture, uv);
	vec4 replace_texel = Texel(replace_texture, uv);

	float replace_a = floor(max(texel.a, ceil(replace_texel.a))); // 0 if replace_texel.a is above 0, 1 if replace_texel.a is 0
	float original_a = 1.0 - replace_a;

	// return texel * (original_a * old_alpha) + replace_texel * replace_a;
	vec4 output_color = vec4(0.0, 0.0, 0.0, 0.0);
	if (replace_texel.a > 0.0) {
		output_color = replace_texel;
	} else {
		output_color = vec4(texel.rgb * old_alpha, texel.a);
	}
	// if (is_approx_equal(output_color, mask_color)) {
	// 	return vec4(0.0, 0.0, 0.0, 0.0);
	// } else {
		return output_color;
	// }
}
