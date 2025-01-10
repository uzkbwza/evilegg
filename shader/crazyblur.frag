// use this with a 100% white texture to get a crazy blur effect

uniform vec2 viewport_size;      // Size of the viewport in pixels
uniform sampler2D pixel_texture; // The overlay image texture

uniform float tile_size = 1.0;         // Size of each tile in pixels
uniform float image_size = 2;        // Size (diameter) of the overlay image, should be > tile_size

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    // Convert texture coordinates to screen-space pixel coordinates
    vec2 pixel_coords = texture_coords * viewport_size;

    // Calculate the tile index for the current fragment
    vec2 tile_index = floor(pixel_coords / tile_size);

    // Determine how many tiles the image can overlap
    float tile_range = ceil((image_size / 2.0) / tile_size);

    vec4 accumulated_color = vec4(0.0);

    // Loop over neighboring tiles that could contribute to this fragment
    for (int dx = -int(tile_range); dx <= int(tile_range); dx++) {
        for (int dy = -int(tile_range); dy <= int(tile_range); dy++) {
            vec2 neighbor_tile_index = tile_index + vec2(float(dx), float(dy));

            // Compute the center position of the neighbor tile
            vec2 tile_center = (neighbor_tile_index + 0.5) * tile_size;

            // Calculate the offset from the tile center to the fragment position
            vec2 offset = pixel_coords - tile_center;

            float distance = length(offset);

            // Check if the fragment is within the overlay image's radius
            if (distance < image_size / 2.0) {
                // Map the offset to [0, 1] range for texture sampling
                vec2 uv = offset / image_size + 0.5;

                // Ensure uv coordinates are within [0, 1] to avoid sampling outside the texture
                if (uv.x >= 0.0 && uv.x <= 1.0 && uv.y >= 0.0 && uv.y <= 1.0) {
                    // Sample the overlay image texture
                    vec4 image_color = Texel(pixel_texture, uv);

                    // Accumulate the color (consider alpha blending if needed)
                    accumulated_color.r = max(accumulated_color.r, image_color.r);
					accumulated_color.g = max(accumulated_color.g, image_color.g);
					accumulated_color.b = max(accumulated_color.b, image_color.b);
					accumulated_color.a = max(accumulated_color.a, image_color.a);
                }
            }
        }
    }

    // Sample the main texture
    vec4 texel = Texel(texture, texture_coords);

    // Combine the accumulated color with the main texture color
    vec4 final_color = texel * accumulated_color;

    // Optionally clamp the final color to prevent values exceeding 1.0
    final_color = clamp(final_color, 0.0, 1.0);

    return final_color;
}
