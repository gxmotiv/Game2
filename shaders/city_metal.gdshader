shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec3 base_color : source_color = vec3(0.075, 0.12, 0.15);
uniform float metallic_value : hint_range(0.0, 1.0) = 0.48;
uniform float roughness_value : hint_range(0.0, 1.0) = 0.57;

varying vec3 world_position;
varying vec3 world_normal;

float hash21(vec2 p) {
	p = fract(p * vec2(127.1, 311.7));
	p += dot(p, p + 19.19);
	return fract(p.x * p.y);
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 n = abs(normalize(world_normal));
	vec2 coords = n.y > 0.65 ? world_position.xz : (n.x > 0.65 ? world_position.zy : world_position.xy);
	float brushed = hash21(floor(coords * vec2(4.0, 38.0)));
	float panel_line = 1.0 - step(0.018, fract(coords.y * 0.7));
	vec3 color = base_color * (0.94 + brushed * 0.12);
	color = mix(color, color * 0.55, panel_line * 0.30);

	ALBEDO = color;
	METALLIC = metallic_value;
	ROUGHNESS = roughness_value;
}