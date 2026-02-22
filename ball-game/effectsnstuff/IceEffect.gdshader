shader_type canvas_item;

uniform vec4 frost_color : source_color = vec4(0.5, 0.8, 1.0, 0.6);

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    // Mix the original sprite color with a light blue frost color
    COLOR = mix(tex_color, frost_color, 0.5 * tex_color.a);
    COLOR.a = tex_color.a; // Keep original transparency
}