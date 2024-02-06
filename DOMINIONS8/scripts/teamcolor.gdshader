shader_type canvas_item;

uniform vec4 new_color: source_color;

void fragment() {
	vec4 current_color = texture(TEXTURE, UV);
	if (current_color.rba == vec3(0, 0, 1) && current_color.g > 0.0)
		COLOR.rgb = new_color.rgb * current_color.g;
}