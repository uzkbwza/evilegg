uniform vec2 viewport_size;
uniform vec2 canvas_size;
uniform vec2 canvas_pos;

uniform float brightness;
uniform float saturation;
uniform float hue;

uniform bool invert_colors;

// All components are in the range [0…1], including hue.
vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

// All components are in the range [0…1], including hue.
vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float map(float value, float min1, float max1, float min2, float max2) {
  return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){

	vec4 texel = Texel(texture, texture_coords);
	
	vec3 rgb = texel.rgb;

    if (invert_colors) {
        rgb = vec3(1.0) - rgb;
    }

	vec3 hsv = rgb2hsv(rgb);

	

	hsv.x = mod(hsv.x + hue, 1.0);
	hsv.y = max(0.0, min(1.0, hsv.y * saturation));
	hsv.z = max(0.0, min(1.0, hsv.z * brightness));

	rgb = hsv2rgb(hsv);

	texel.rgb = rgb;


	return texel;
}
