uniform vec2 viewport_size;      
uniform sampler2D pixel_texture; 

uniform float effect_strength = 0.3; 

uniform float brightness = 1.8;

uniform float min_brightness = 0.0;


vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec2 pixel_coords = texture_coords * viewport_size;
	vec2 pixel_uv = mod(pixel_coords, 1.0);


	vec2 offset = vec2(0.0);

	vec4 overlay = Texel(pixel_texture, pixel_uv + offset);
	
	vec4 base = Texel(texture, texture_coords);

	base.r = max(base.r, min_brightness);
	base.g = max(base.g, min_brightness);
	base.b = max(base.b, min_brightness);


    vec4 final_color = mix(base, base * overlay * brightness, effect_strength);

    return final_color;
}
