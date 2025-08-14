vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    if (Texel(texture, texture_coords).rgb == vec3(0.0)) {
        
    }
    return vec4(1.0);
}
