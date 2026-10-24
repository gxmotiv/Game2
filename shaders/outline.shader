shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled;

uniform vec4 outline_color : source_color = vec4(0.2, 0.8, 1.0, 1.0);
uniform float outline_width : hint_range(0.0, 0.1) = 0.02;

void vertex() {
	VERTEX += NORMAL * outline_width;
}

void fragment() {
	ALBEDO = outline_color.rgb;
	ALPHA = outline_color.a;
}