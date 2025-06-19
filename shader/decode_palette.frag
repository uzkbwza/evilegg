uniform vec4 palette[256];
uniform int palette_size;
uniform int palette_offset;

bool is_approx_equal(vec4 color1, vec4 color2, float threshold) {
    vec4 diff = color1 - color2;
    return length(diff) < threshold;
}

vec4 decode_palette(vec4 encoded_color, vec4 palette[256], int palette_size, int palette_offset) {
    if (encoded_color.a == 0.0) {
        return vec4(0.0);
    }
    
    float index = encoded_color.g * 255.0;

	int i = int(mod(int(index) + palette_offset + 0.5, palette_size));
	vec4 palette_color = vec4(palette[i]);

    
    return vec4(palette_color.rgb, encoded_color.a * palette_color.a);
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 texel = Texel(texture, texture_coords);
    
    vec4 encoded = decode_palette(texel, palette, palette_size, palette_offset);

    return encoded;
}
