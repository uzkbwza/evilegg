uniform vec2 viewport_size;      
uniform sampler2D pixel_texture; 

uniform float effect_strength = 0.3; 

uniform float brightness = 1.8;

uniform float min_brightness = 0.0;

uniform float boost = 1.0;

uniform float overlay_power = 2.0;

uniform float saturation_modifier = 1.0;
uniform float luminance_modifier = 1.0;
uniform float contrast_modifier = 1.0;

const float EPSILON = 1e-10;


float hue2rgb(float f1, float f2, float hue) {
    if (hue < 0.0)
        hue += 1.0;
    else if (hue > 1.0)
        hue -= 1.0;
    float res;
    if ((6.0 * hue) < 1.0)
        res = f1 + (f2 - f1) * 6.0 * hue;
    else if ((2.0 * hue) < 1.0)
        res = f2;
    else if ((3.0 * hue) < 2.0)
        res = f1 + (f2 - f1) * ((2.0 / 3.0) - hue) * 6.0;
    else
        res = f1;
    return res;
}

vec3 hsl2rgb(vec3 hsl) {
    vec3 rgb;
    
    if (hsl.y == 0.0) {
        rgb = vec3(hsl.z); // Luminance
    } else {
        float f2;
        
        if (hsl.z < 0.5)
            f2 = hsl.z * (1.0 + hsl.y);
        else
            f2 = hsl.z + hsl.y - hsl.y * hsl.z;
            
        float f1 = 2.0 * hsl.z - f2;
        
        rgb.r = hue2rgb(f1, f2, hsl.x + (1.0/3.0));
        rgb.g = hue2rgb(f1, f2, hsl.x);
        rgb.b = hue2rgb(f1, f2, hsl.x - (1.0/3.0));
    }   
    return rgb;
}

vec3 hsl2rgb(float h, float s, float l) {
    return hsl2rgb(vec3(h, s, l));
}



vec3 rgb2hcv(in vec3 rgb)
{
    // RGB [0..1] to Hue-Chroma-Value [0..1]
    // Based on work by Sam Hocevar and Emil Persson
    vec4 p = (rgb.g < rgb.b) ? vec4(rgb.bg, -1., 2. / 3.) : vec4(rgb.gb, 0., -1. / 3.);
    vec4 q = (rgb.r < p.x) ? vec4(p.xyw, rgb.r) : vec4(rgb.r, p.yzx);
    float c = q.x - min(q.w, q.y);
    float h = abs((q.w - q.y) / (6. * c + EPSILON) + q.z);
    return vec3(h, c, q.x);
}


vec3 rgb2hsl(in vec3 rgb)
{
    // RGB [0..1] to Hue-Saturation-Lightness [0..1]
    vec3 hcv = rgb2hcv(rgb);
    float z = hcv.z - hcv.y * 0.5;
    float s = hcv.y / (1. - abs(z * 2. - 1.) + EPSILON);
    return vec3(hcv.x, s, z);
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec2 pixel_coords = texture_coords * viewport_size;
	vec2 pixel_uv = mod(pixel_coords, 1.0);

	vec2 offset = vec2(0.0);

	vec4 overlay = Texel(pixel_texture, pixel_uv + offset);
	
	vec4 base = Texel(texture, texture_coords);
	float a = base.r + base.g + base.b;
	a = a / 3.0;

	float value = max(base.r, max(base.g, base.b));

	base.r = max(base.r, min_brightness + min_brightness * value);
	base.g = max(base.g, min_brightness + min_brightness * value);
	base.b = max(base.b, min_brightness + min_brightness * value);

	vec4 modifier = vec4(1.0, 1.0, 1.0, 1.0) * pow(overlay.r, overlay_power);

    vec4 modified_color = mix(base, base * (modifier) * brightness, effect_strength);

	vec3 hsl = rgb2hsl(modified_color.rgb);
	hsl.g = hsl.g * saturation_modifier;
	hsl.g = clamp(hsl.g, 0.0, 1.0);
	hsl.b = hsl.b * luminance_modifier;
	hsl.b = clamp(hsl.b, 0.0, 1.0);
	modified_color.rgb = hsl2rgb(hsl);

	modified_color.rgb = (modified_color.rgb - 0.5) * max(0.0, contrast_modifier) + 0.5;

	// modified_color.a = a;

    return modified_color;
}
