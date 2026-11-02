shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec3 fabric_color = vec3(0.018, 0.032, 0.052);
uniform float weave_scale : hint_range(8.0, 80.0) = 34.0;

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
	vec2 weave_uv = coords * weave_scale;
	float thread_x = sin(weave_uv.x * 6.28318);
	float thread_y = sin(weave_uv.y * 6.28318);
	float weave = (thread_x * thread_y) * 0.018;
	float grain = hash21(floor(weave_uv * 2.0)) * 0.035;
	ALBEDO = fabric_color * (0.96 + weave + grain);
	ROUGHNESS = 0.94;
	METALLIC = 0.015;
}