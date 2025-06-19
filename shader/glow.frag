uniform vec2 viewport_size;
uniform vec2 canvas_size;
uniform vec2 canvas_pos;

// New uniforms for the pre-aberration blur
uniform float pre_blur_size = 0.08;           // Controls the pre-aberration blur size
uniform int pre_blur_samples = 7;            // Controls the number of samples in the pre-aberration blur

uniform float intensity = 0.5;
uniform float glow_curve = 1;
uniform float glow_boost = 0.0;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = texture_coords;
    vec2 pixel_coords = uv * viewport_size;
    // vec2 pixel_uv = mod(pixel_coords, 1.0);
    vec2 pixel_size = 1.0 / viewport_size;
    vec2 screen_pixel_size = 1.0 / canvas_size;
    float pixel_scale = screen_pixel_size.x / pixel_size.x;

    // Pre-aberration blur
    vec4 blurred_color = vec4(0.0);
    float pre_total_weight = 0.0;

    int pre_half_samples = pre_blur_samples / 2;
    for (int i = -pre_half_samples; i <= pre_half_samples; i++) {
        for (int j = -pre_half_samples; j <= pre_half_samples; j++) {
            vec2 offset = vec2(float(i), float(j)) * pre_blur_size * pixel_size;
            float weight = exp(-0.5 * (float(i * i + j * j) / float(pre_half_samples * pre_half_samples)));
			weight = pow(weight, glow_curve);
            blurred_color += Texel(texture, uv + offset) * weight; 
            pre_total_weight += weight;
        }
    }
    blurred_color /= pre_total_weight;

	vec4 base = Texel(texture, uv);

    // Now apply chromatic aberration to the blurred color
    float r = max(blurred_color.r, base.r) + (blurred_color.r * glow_boost);
    float g = max(blurred_color.g, base.g) + (blurred_color.g * glow_boost);
    float b = max(blurred_color.b, base.b) + (blurred_color.b * glow_boost);
    float a = blurred_color.a;




    vec4 pixel = vec4(mix(base.rgb, vec3(r, g, b), intensity), a);

	pixel.a = 1.0;

    return pixel;
}
