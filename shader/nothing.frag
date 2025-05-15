uniform vec2 viewport_size;
uniform vec2 canvas_size;
uniform vec2 canvas_pos;

vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){

	vec4 texel = Texel(texture, texture_coords);
	
	return texel;
}
