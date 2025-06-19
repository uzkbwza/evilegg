uniform vec2 viewport_size;
uniform vec2 canvas_size;
uniform vec2 canvas_pos;
uniform vec4 mask_color;

const float TOLERANCE = 0.01;

bool is_approx_equal(vec4 a, vec4 b) {
	return abs(a.r - b.r) < TOLERANCE && abs(a.g - b.g) < TOLERANCE && abs(a.b - b.b) < TOLERANCE;
}

vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
	vec2 uv = texture_coords;

	vec4 texel = Texel(texture, uv);

	if (is_approx_equal(texel, mask_color)) {
		return vec4(0.0, 0.0, 0.0, 0.0);
	} else {
		return texel;
	}
}
