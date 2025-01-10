uniform vec2 viewport_size;
uniform vec2 canvas_size;
uniform vec2 canvas_pos;

vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
	vec2 uv = texture_coords;
	vec2 pixel_coords = uv * viewport_size;
	vec2 pixel_uv = mod(pixel_coords, 1.0);

	vec4 texel = Texel(texture, uv);
	
	return vec4(pixel_uv.xy, 1.0, 1.0) * texel;
}
