shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec3 base_color : source_color = vec3(0.035, 0.052, 0.072);
uniform float roughness_value : hint_range(0.0, 1.0) = 0.88;
uniform float grain_strength : hint_range(0.0, 0.3) = 0.12;

varying vec3 world_position;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_position.xz;
	float coarse = hash21(floor(p * 1.7));
	float medium = hash21(floor(p * 8.0));
	float fine = hash21(floor(p * 28.0));
	float aggregate = (coarse * 0.25 + medium * 0.35 + fine * 0.40) - 0.5;

	float patch = hash21(floor(p * 0.22));
	vec3 color = base_color * (0.96 + aggregate * grain_strength + (patch - 0.5) * 0.08);
	float worn_line = smoothstep(0.985, 1.0, hash21(floor(p * vec2(0.16, 0.11))));
	color = mix(color, color * 1.20, worn_line * 0.08);

	ALBEDO = color;
	ROUGHNESS = roughness_value;
	METALLIC = 0.04;
}