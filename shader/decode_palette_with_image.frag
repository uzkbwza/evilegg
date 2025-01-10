uniform sampler2D palette;
uniform int palette_size;
uniform int palette_offset;

bool is_approx_equal(vec3 color1, vec3 color2, float threshold) {
    vec3 diff = color1 - color2;
    return length(diff) < threshold;
}

vec4 decode_palette(vec4 encoded_color, sampler2D palette, int palette_size, int palette_offset) {
    if (encoded_color.a == 0.0) {
        return vec4(0.0);
    }
    
    float index = encoded_color.g * 255.0;

	float i = 0.5 + int(mod(int(index) + palette_offset, palette_size));
	vec4 palette_color = texture2D(palette, vec2(i / palette_size, 0));

    return vec4(palette_color.rgb, encoded_color.a);
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 texel = texture2D(texture, texture_coords);
    
    vec4 encoded = decode_palette(texel, palette, palette_size, palette_offset);

    return encoded;
}
