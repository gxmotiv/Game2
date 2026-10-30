shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec3 base_color : source_color = vec3(0.16, 0.21, 0.25);
uniform vec3 seam_color : source_color = vec3(0.075, 0.105, 0.13);
uniform float tile_scale : hint_range(0.05, 2.0) = 0.38;
uniform float seam_width : hint_range(0.005, 0.08) = 0.018;
uniform float roughness_value : hint_range(0.0, 1.0) = 0.91;

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
	vec2 cell = fract(coords * tile_scale);
	float seam = max(1.0 - step(seam_width, cell.x), 1.0 - step(seam_width, cell.y));
	float noise_a = hash21(floor(coords * 3.0));
	float noise_b = hash21(floor(coords * 17.0));
	float variation = 0.91 + noise_a * 0.10 + noise_b * 0.035;
	vec3 color = base_color * variation;
	color = mix(color, seam_color, seam * 0.72);

	ALBEDO = color;
	ROUGHNESS = roughness_value;
	METALLIC = 0.015;
}