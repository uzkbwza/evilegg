uniform vec3 palette[256];
uniform int palette_size;

bool is_approx_equal(vec3 color1, vec3 color2, float threshold) {
    vec3 diff = color1 - color2;
   return dot(diff, diff) < threshold * threshold;
}


vec3 rgb_to_hsl( in vec3 c ){
  float h = 0.0;
	float s = 0.0;
	float l = 0.0;
	float r = c.r;
	float g = c.g;
	float b = c.b;
	float cMin = min( r, min( g, b ) );
	float cMax = max( r, max( g, b ) );

	l = ( cMax + cMin ) / 2.0;
	if ( cMax > cMin ) {
		float cDelta = cMax - cMin;
        
        //s = l < .05 ? cDelta / ( cMax + cMin ) : cDelta / ( 2.0 - ( cMax + cMin ) ); Original
		s = l < .0 ? cDelta / ( cMax + cMin ) : cDelta / ( 2.0 - ( cMax + cMin ) );
        
		if ( r == cMax ) {
			h = ( g - b ) / cDelta;
		} else if ( g == cMax ) {
			h = 2.0 + ( b - r ) / cDelta;
		} else {
			h = 4.0 + ( r - g ) / cDelta;
		}

		if ( h < 0.0) {
			h += 6.0;
		}
		h = h / 6.0;
	}
	return vec3( h, s, l );
}

// Converts a color to a palette index encoded in a vec4
vec4 encode_palette(vec3 color, float alpha, vec3 palette[256], int palette_size) {
    if (alpha == 0.0) {
        return vec4(0.0);
    }

    float index = 0.0;
    float threshold = 0.001;
    float min_dist = 100000.0; // Large initial value
    
    // Search through palette colors
    for (int i = 0; i < 256; i++) {
        if (i >= palette_size) break; // Changed from '>' to '>=' for correctness
        
        vec3 palette_color = palette[i];
        vec3 diff = color - palette_color;
        float dist = dot(diff, diff); // Squared distance, avoiding sqrt
        
        if (dist < min_dist) {
            min_dist = dist;
            index = float(i);
            // Remove early exit to find closest color instead of first match
        }
    }

	vec3 hsl = rgb_to_hsl(color);

	// lightness in the first channel, palette index in the second channel, hue in the third channel
	// saturation is not used
    return vec4(hsl.z, index / 255.0, hsl.x, 1.0);
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 texel = Texel(texture, texture_coords);
    
    // Convert to palette index
    vec4 encoded = encode_palette(texel.rgb, texel.a, palette, palette_size);
    
    // Convert back to color
    return encoded;
}
