 shader_type canvas_item;

uniform float pixel_size = 128.0; // Size of the target pixels
uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;

void fragment() {
    // Calculate the grid coordinates based on pixel size
    vec2 grid_uv = round(SCREEN_UV / (SCREEN_PIXEL_SIZE * pixel_size)) * (SCREEN_PIXEL_SIZE * pixel_size);
    
    // Sample the screen behind the ColorRect at the grid position
    vec4 text = texture(screen_texture, grid_uv);
    
    COLOR = text;
}