uniform vec2 viewport_size;
uniform vec2 canvas_size;
uniform vec2 canvas_pos;

// New uniforms for the pre-aberration blur
uniform float pre_blur_size = 0.08;           // Controls the pre-aberration blur size
uniform int pre_blur_samples = 7;            // Controls the number of samples in the pre-aberration blur

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = texture_coords;
    vec2 pixel_coords = uv * viewport_size;
    // vec2 pixel_uv = mod(pixel_coords, 1.0);
    vec2 pixel_size = 1.0 / viewport_size;
    vec2 screen_pixel_size = 1.0 / canvas_size;
    float pixel_scale = screen_pixel_size.x / pixel_size.x;

    // Separable-like blur approximation (cross shape)
    vec4 blurred_color = vec4(0.0);
    float pre_total_weight = 0.0;
    int pre_half_samples = pre_blur_samples / 2;
    
    if (pre_blur_size > 0.0 && pre_half_samples > 0) {
        vec2 radius = pre_blur_size * pixel_size;
        float scale = float(pre_half_samples * pre_half_samples);
        
        // Center pixel
        blurred_color += Texel(texture, uv);
        pre_total_weight += 1.0;
        
        // Horizontal
        for (int i = 1; i <= pre_half_samples; i++) {
            float fi = float(i);
            float weight = exp(-0.5 * (fi*fi)/scale);
            vec2 offset = vec2(fi * radius.x, 0.0);
            blurred_color += Texel(texture, uv + offset) * weight;
            blurred_color += Texel(texture, uv - offset) * weight;
            pre_total_weight += 2.0 * weight;
        }

        // Vertical
        for (int j = 1; j <= pre_half_samples; j++) {
            float fj = float(j);
            float weight = exp(-0.5 * (fj*fj)/scale);
            vec2 offset = vec2(0.0, fj * radius.y);
            blurred_color += Texel(texture, uv + offset) * weight;
            blurred_color += Texel(texture, uv - offset) * weight;
            pre_total_weight += 2.0 * weight;
        }

        if (pre_total_weight > 0.0) {
            blurred_color /= pre_total_weight;
        }
    } else {
        blurred_color = Texel(texture, uv);
    }

    // Now apply chromatic aberration to the blurred color
    float r = blurred_color.r;
    float g = blurred_color.g;
    float b = blurred_color.b;
    float a = blurred_color.a;

    vec4 pixel = vec4(r, g, b, a);

	pixel.a = 1.0;

    return pixel;
}
