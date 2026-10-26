shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_test_disabled;

uniform vec4 cone_color : source_color = vec4(1.0, 0.3, 0.1, 0.15);
uniform float cone_angle : hint_range(0.0, 180.0) = 90.0;
uniform float cone_range : hint_range(0.0, 50.0) = 15.0;

void vertex() {
	// Cone geometry is handled by mesh, just pass through
}

void fragment() {
	ALBEDO = cone_color.rgb;
	ALPHA = cone_color.a;
}