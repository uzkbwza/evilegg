uniform vec2 viewport_size;
uniform vec2 canvas_size;
uniform vec2 canvas_pos;

uniform float rgb_amount = 0.15;
uniform float rgb_brightness = 4.55;
uniform float border_size = 150.0;
uniform float border_feather = 0.5;
uniform float border_amount = 0.5; // 0.5
uniform float correction = 0.8;
uniform float roundness = 1;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = texture_coords;
    vec2 pixel_coords = uv * viewport_size;
    vec2 pixel_uv = mod(pixel_coords, 1.0);
    vec2 pixel_size = 1.0 / viewport_size;
    vec2 screen_pixel_size = 1.0 / canvas_size;
    float pixel_scale = screen_pixel_size.x / pixel_size.x;

    float dist = (1.0 - pixel_uv.x);
    float bsize = (pixel_scale * 0.002) * border_size;
    dist = min(1.0 - pixel_uv.y, dist);

    float dist2 = pixel_uv.x;
    dist2 = min(1.0 - pixel_uv.y, dist2);
    float border = 0.5 + smoothstep(bsize - border_feather, bsize + border_feather, dist) * 0.5;
	float border2 = 1.0 - pow(length(vec2(0.5, 0.5) - pixel_uv), 2.5);
	border = mix(border, border2, roundness);

	vec4 texel = Texel(texture, uv);

	float p = 2.0;
	float bo = pow(border, p);
	float bo2 = pow(correction, p) + pow(border, p);

    vec4 pixel = texel * mix(1.0, bo, border_amount) * mix(1.0, bo2, border_amount);

	pixel.a = 1.0;

    return pixel;
}
