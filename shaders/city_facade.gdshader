shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec3 base_color : source_color = vec3(0.24, 0.31, 0.37);
uniform float roughness_value : hint_range(0.0, 1.0) = 0.86;
uniform float panel_scale : hint_range(0.1, 2.0) = 0.62;

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
	vec2 panel = coords * panel_scale;
	vec2 edge = min(fract(panel), 1.0 - fract(panel));
	float seam = 1.0 - step(0.025, min(edge.x, edge.y));
	float panel_noise = hash21(floor(panel * 4.0));
	float speckle = hash21(floor(coords * 13.0));
	float variation = 0.92 + panel_noise * 0.10 + speckle * 0.025;
	vec3 tinted = base_color * COLOR.rgb * variation;
	tinted = mix(tinted, tinted * 0.56, seam * 0.20);

	ALBEDO = tinted;
	ROUGHNESS = roughness_value;
	METALLIC = 0.18;
}