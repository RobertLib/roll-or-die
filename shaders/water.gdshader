shader_type spatial;
render_mode blend_mix, cull_back, diffuse_lambert, specular_schlick_ggx;

uniform vec4 water_color : source_color = vec4(0.15, 0.45, 0.75, 0.8);
uniform float wave_speed : hint_range(0.1, 5.0) = 1.2;
uniform float wave_height : hint_range(0.0, 0.5) = 0.07;
uniform float wave_frequency : hint_range(0.1, 10.0) = 2.5;

// Ripple effect: origin in local XZ, ripple_time = -1 means inactive
uniform vec2 ripple_origin = vec2(0.0, 0.0);
uniform float ripple_time = -1.0;
uniform float ripple_height : hint_range(0.0, 1.0) = 0.5;
uniform float ripple_speed : hint_range(0.5, 5.0) = 2.5;

void vertex() {
	float t = TIME * wave_speed;
	VERTEX.y += sin(VERTEX.x * wave_frequency + t) * wave_height;
	VERTEX.y += sin(VERTEX.z * wave_frequency * 0.8 + t * 1.2) * wave_height * 0.6;
	VERTEX.y += sin((VERTEX.x + VERTEX.z) * wave_frequency * 0.5 + t * 0.9) * wave_height * 0.4;

	if (ripple_time >= 0.0) {
		float dist = length(vec2(VERTEX.x, VERTEX.z) - ripple_origin);
		float wave_front = ripple_time * ripple_speed;
		float envelope = max(0.0, 1.0 - abs(dist - wave_front) / 1.2);
		float decay = exp(-ripple_time * 1.5);
		VERTEX.y += sin(dist * 5.0 - ripple_time * 10.0) * envelope * decay * ripple_height;
	}
}

void fragment() {
	ALBEDO = water_color.rgb;
	ALPHA = water_color.a;
	SPECULAR = 0.6;
	ROUGHNESS = 0.05;
}
