uniform float brightness;
uniform float saturation;
uniform float hue;

uniform bool invert_colors;

//By Björn Ottosson
//https://bottosson.github.io/posts/oklab
//Shader functions adapted by "mattz"
//https://www.shadertoy.com/view/WtccD7

vec3 oklab_from_linear(vec3 linear)
{
    const mat3 im1 = mat3(0.4121656120, 0.2118591070, 0.0883097947,
                          0.5362752080, 0.6807189584, 0.2818474174,
                          0.0514575653, 0.1074065790, 0.6302613616);
                       
    const mat3 im2 = mat3(+0.2104542553, +1.9779984951, +0.0259040371,
                          +0.7936177850, -2.4285922050, +0.7827717662,
                          -0.0040720468, +0.4505937099, -0.8086757660);
                       
    vec3 lms = im1 * linear;
    
    // Component-wise cube root since this GLSL version doesn't support pow on vectors
    vec3 lms_cbrt = vec3(sign(lms.x) * pow(abs(lms.x), 1.0/3.0),
                         sign(lms.y) * pow(abs(lms.y), 1.0/3.0),
                         sign(lms.z) * pow(abs(lms.z), 1.0/3.0));
            
    return im2 * lms_cbrt;
}

vec3 linear_from_oklab(vec3 oklab)
{
    const mat3 m1 = mat3(+1.000000000, +1.000000000, +1.000000000,
                         +0.396337777, -0.105561346, -0.089484178,
                         +0.215803757, -0.063854173, -1.291485548);
                       
    const mat3 m2 = mat3(+4.076724529, -1.268143773, -0.004111989,
                         -3.307216883, +2.609332323, -0.703476310,
                         +0.230759054, -0.341134429, +1.706862569);
    vec3 lms = m1 * oklab;
    
    return m2 * (lms * lms * lms);
}

//By Inigo Quilez, under MIT license
//https://www.shadertoy.com/view/ttcyRS
vec3 oklab_mix(vec3 lin1, vec3 lin2, float a)
{
    // https://bottosson.github.io/posts/oklab
    const mat3 kCONEtoLMS = mat3(                
         0.4121656120,  0.2118591070,  0.0883097947,
         0.5362752080,  0.6807189584,  0.2818474174,
         0.0514575653,  0.1074065790,  0.6302613616);
    const mat3 kLMStoCONE = mat3(
         4.0767245293, -1.2681437731, -0.0041119885,
        -3.3072168827,  2.6093323231, -0.7034763098,
         0.2307590544, -0.3411344290,  1.7068625689);
                    
    // rgb to cone (arg of pow can't be negative)
    vec3 lms1_linear = kCONEtoLMS * lin1;
    vec3 lms2_linear = kCONEtoLMS * lin2;
    
    // Component-wise cube root since this GLSL version doesn't support pow on vectors
    vec3 lms1 = vec3(pow(lms1_linear.x, 1.0/3.0),
                     pow(lms1_linear.y, 1.0/3.0),
                     pow(lms1_linear.z, 1.0/3.0));
    vec3 lms2 = vec3(pow(lms2_linear.x, 1.0/3.0),
                     pow(lms2_linear.y, 1.0/3.0),
                     pow(lms2_linear.z, 1.0/3.0));
    
    // lerp
    vec3 lms = mix(lms1, lms2, a);
    // gain in the middle (no oklab anymore, but looks better?)
    // lms *= 1.0 + 0.2 * a * (1.0 - a);
    // cone to rgb
    return kLMStoCONE * (lms * lms * lms);
}

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

    
    // Apply hue and brightness adjustments using HSV
    if (hue != 0.0 || brightness != 1.0) {
        vec3 hsv = rgb2hsv(rgb);
        hsv.x = mod(hsv.x + hue, 1.0);
        hsv.z = max(0.0, min(1.0, hsv.z * brightness));
        rgb = hsv2rgb(hsv);
    }


    // Apply saturation using oklab mixing
    if (saturation != 1.0) {
        // Get the oklab representation of the original pixel
        vec3 oklab_original = oklab_from_linear(rgb);
        
        // Create a grayscale version by setting a and b channels to 0 (keeping only lightness)
        vec3 oklab_gray = vec3(oklab_original.x, 0.0, 0.0);
        vec3 rgb_gray = linear_from_oklab(oklab_gray);
        
        // Mix between grayscale and original based on saturation
        // saturation = 1.0 means full color, saturation = 0.0 means full gray
        rgb = oklab_mix(rgb_gray, rgb, saturation);
    }

	texel.rgb = rgb;

	return texel;
}
