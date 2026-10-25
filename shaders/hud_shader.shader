shader_type canvas_item;

uniform vec4 accent_color : source_color = vec4(0.2, 0.8, 1.0, 1.0);
uniform float pulse_speed : hint_range(0.0, 10.0) = 2.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float pulse = sin(TIME * pulse_speed) * 0.5 + 0.5;
	vec3 color = mix(tex.rgb, accent_color.rgb, tex.a * pulse * 0.3);
	COLOR = vec4(color, tex.a);
}