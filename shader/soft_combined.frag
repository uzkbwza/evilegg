uniform vec2 viewport_size;
uniform vec2 canvas_size;
uniform vec2 canvas_pos;

// Blur settings
uniform float blur_size = 0.08;
uniform int blur_samples = 7;

// Aberration settings
uniform float aberration_amount = 0.3;
uniform float aberration_strength = 0.6;
uniform int aberration_blur_samples = 7;

// Glow settings
uniform float glow_size = 0.5;
uniform int glow_samples = 8;
uniform float glow_intensity = 0.25;
uniform float glow_curve = 1.5;
uniform float glow_boost = 0.025;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = texture_coords;
    vec2 pixel_size = 1.0 / viewport_size;
    vec2 screen_pixel_size = 1.0 / canvas_size;
    float pixel_scale = screen_pixel_size.x / pixel_size.x;

    // === 1. Initial soft blur (cross-shaped for performance) ===
    vec4 blurred_color = vec4(0.0);
    float blur_total_weight = 0.0;
    int blur_half = blur_samples / 2;

    if (blur_size > 0.0 && blur_half > 0) {
        vec2 radius = blur_size * pixel_size;
        float scale = float(blur_half * blur_half);

        // Center pixel
        blurred_color += Texel(texture, uv);
        blur_total_weight += 1.0;

        // Horizontal
        for (int i = 1; i <= blur_half; i++) {
            float fi = float(i);
            float weight = exp(-0.5 * (fi * fi) / scale);
            vec2 offset = vec2(fi * radius.x, 0.0);
            blurred_color += Texel(texture, uv + offset) * weight;
            blurred_color += Texel(texture, uv - offset) * weight;
            blur_total_weight += 2.0 * weight;
        }

        // Vertical
        for (int j = 1; j <= blur_half; j++) {
            float fj = float(j);
            float weight = exp(-0.5 * (fj * fj) / scale);
            vec2 offset = vec2(0.0, fj * radius.y);
            blurred_color += Texel(texture, uv + offset) * weight;
            blurred_color += Texel(texture, uv - offset) * weight;
            blur_total_weight += 2.0 * weight;
        }

        blurred_color /= blur_total_weight;
    } else {
        blurred_color = Texel(texture, uv);
    }

    // === 2. Chromatic aberration ===
    float r = 0.0;
    float g = blurred_color.g;
    float b = 0.0;

    int aberration_half = aberration_blur_samples / 2;
    if (aberration_strength > 0.0 && aberration_half > 0) {
        float aberration_total_weight = 0.0;
        float aberration = max(aberration_amount, sign(aberration_amount) * pixel_scale);
        float aberration_offset = aberration * pixel_size.x;
        float aberration_kernel_scale = float(aberration_half);
        float aberration_sample_step = (0.25 / aberration_kernel_scale) * pixel_size.x;

        for (int i = -aberration_half; i <= aberration_half; i++) {
            float fi = float(i);
            float sample_offset = fi * aberration_sample_step;
            float weight = exp(-0.5 * (fi * fi) / (aberration_kernel_scale * aberration_kernel_scale));
            aberration_total_weight += weight;

            // Sample from the blurred result approximation by sampling original with offset
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

    vec4 aberrated = vec4(r, g, b, blurred_color.a);

    // === 3. Glow (larger blur for bloom effect) ===
    vec4 glow_color = vec4(0.0);
    float glow_total_weight = 0.0;
    int glow_half = glow_samples / 2;

    if (glow_size > 0.0 && glow_half > 0 && glow_intensity > 0.0) {
        vec2 glow_radius = glow_size * pixel_size;
        float glow_scale = float(glow_half * glow_half);

        // Center pixel
        float weight = 1.0;
        glow_color += Texel(texture, uv) * weight;
        glow_total_weight += weight;

        // Horizontal
        for (int i = 1; i <= glow_half; i++) {
            float fi = float(i);
            weight = exp(-0.5 * (fi * fi) / glow_scale);
            weight = pow(weight, glow_curve);
            vec2 offset = vec2(fi * glow_radius.x, 0.0);
            glow_color += Texel(texture, uv + offset) * weight;
            glow_color += Texel(texture, uv - offset) * weight;
            glow_total_weight += 2.0 * weight;
        }

        // Vertical
        for (int j = 1; j <= glow_half; j++) {
            float fj = float(j);
            weight = exp(-0.5 * (fj * fj) / glow_scale);
            weight = pow(weight, glow_curve);
            vec2 offset = vec2(0.0, fj * glow_radius.y);
            glow_color += Texel(texture, uv + offset) * weight;
            glow_color += Texel(texture, uv - offset) * weight;
            glow_total_weight += 2.0 * weight;
        }

        glow_color /= glow_total_weight;
    } else {
        glow_color = aberrated;
    }

    // Combine: base with glow
    vec3 glow_result = max(glow_color.rgb, aberrated.rgb) + (glow_color.rgb * glow_boost);
    vec3 final_color = mix(aberrated.rgb, glow_result, glow_intensity);

    return vec4(final_color, 1.0);
}
