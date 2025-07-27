uniform vec2 viewport_size;
uniform vec2 canvas_size;
uniform vec2 canvas_pos;

uniform float rgb_amount = 0.15;
uniform float rgb_brightness = 4.55;

uniform float aberration_amount = 0.1;
uniform float aberration_strength = 0.6;
uniform float aberration_blur_size = 0.25;   // Controls the aberration blur size
uniform int aberration_blur_samples = 7;     // Controls the number of samples in the aberration blur

// New uniforms for the pre-aberration blur
uniform float pre_blur_size = 0.00;           // Controls the pre-aberration blur size
uniform int pre_blur_samples = 2;            // Controls the number of samples in the pre-aberration blur

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = texture_coords;
    vec2 pixel_size = 1.0 / viewport_size;

    // --- Separable Gaussian Blur ---
    // This is more performant than a 2D blur as it reduces texture fetches
    // from N*N to N+N, where N is the number of samples.

    vec4 blurred_color = vec4(0.0);
    int pre_half_samples = pre_blur_samples / 2;

    if (pre_blur_size > 0.0 && pre_half_samples > 0) {
        vec2 pre_blur_radius = pre_blur_size * pixel_size;
        float pre_kernel_scale = float(pre_half_samples);
        
        // Vertical pass
        vec4 blurred_color_v = vec4(0.0);
        float pre_total_weight_v = 0.0;
        for (int j = -pre_half_samples; j <= pre_half_samples; j++) {
            float fj = float(j);
            float weight = exp(-0.5 * (fj * fj) / (pre_kernel_scale * pre_kernel_scale));
            vec2 offset = vec2(0.0, fj * pre_blur_radius.y);
            blurred_color_v += Texel(texture, uv + offset) * weight;
            pre_total_weight_v += weight;
        }
        blurred_color_v /= pre_total_weight_v;

        // Horizontal pass on vertically blurred results
        float pre_total_weight_h = 0.0;
        for (int i = -pre_half_samples; i <= pre_half_samples; i++) {
            float fi = float(i);
            float weight = exp(-0.5 * (fi * fi) / (pre_kernel_scale * pre_kernel_scale));
            vec2 offset = vec2(fi * pre_blur_radius.x, 0.0);
            blurred_color += Texel(texture, uv + offset) * weight;
            pre_total_weight_h += weight;
        }
        blurred_color /= pre_total_weight_h;
    } else {
        blurred_color = Texel(texture, uv);
    }

    // --- Chromatic Aberration ---
    float r = 0.0;
    float g = blurred_color.g;
    float b = 0.0;
    float a = blurred_color.a;

    int aberration_half_samples = aberration_blur_samples / 2;
    if (aberration_strength > 0.0 && aberration_half_samples > 0) {
        float aberration_total_weight = 0.0;

        vec2 screen_pixel_size = 1.0 / canvas_size;
        float pixel_scale = screen_pixel_size.x / pixel_size.x;
        float aberration = max(aberration_amount, sign(aberration_amount) * pixel_scale);
        float aberration_offset = aberration * pixel_size.x;
        
        float aberration_kernel_scale = float(aberration_half_samples);
        float aberration_sample_step = (aberration_blur_size / aberration_kernel_scale) * pixel_size.x;

        for (int i = -aberration_half_samples; i <= aberration_half_samples; i++) {
            float fi = float(i);
            float sample_offset = fi * aberration_sample_step;
            float weight = exp(-0.5 * (fi * fi) / (aberration_kernel_scale * aberration_kernel_scale));

            aberration_total_weight += weight;

            r += Texel(texture, uv + vec2(aberration_offset + sample_offset, 0.0)).r * weight;
            b += Texel(texture, uv - vec2(aberration_offset + sample_offset, 0.0)).b * weight;
        }

        if (aberration_total_weight > 0.0) {
            r /= aberration_total_weight;
            b /= aberration_total_weight;
        }

        r = mix(r, blurred_color.r, 1.0 - aberration_strength);
        b = mix(b, blurred_color.b, 1.0 - aberration_strength);
    } else {
        r = blurred_color.r;
        b = blurred_color.b;
    }

    vec4 pixel = vec4(r, g, b, a);
	pixel.a = 1.0;
    return pixel;
}
