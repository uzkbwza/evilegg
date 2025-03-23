uniform vec2 viewport_size;
uniform vec2 canvas_size;
uniform vec2 canvas_pos;

float brightness(vec3 c) {
    return dot(c, vec3(0.299, 0.587, 0.114));
}

vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
    vec4 col = Texel(texture, texture_coords);
    
    // Compute brightness
    float b = brightness(color.rgb);

    // Use brightness as alpha
    float alpha = b; // or some function of b

    // Guard against division by zero for purely black pixels:
    if (alpha > 1e-5) {
        // "Unmultiply": so that alpha*color_out = original color
        col.rgb /= alpha;
    } else {
        // If it's completely black, just make it fully transparent
        col.rgb = vec3(0.0);
        alpha = 0.0;
    }

    // Set final alpha
    col.a = alpha;
    	
	return col;
}
