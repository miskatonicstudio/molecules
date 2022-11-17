shader_type canvas_item;

uniform vec4 color : hint_color;
uniform sampler2D noise_texture : hint_albedo;
// Random offset, to make each molecule look a bit differently
uniform float offset : hint_range(0, 1) = 0.1;

const float lightning_smoothness = 0.30;
const float speed = 0.02;


float sample_both_tex(sampler2D tex, vec2 uv1, vec2 uv2) {
	return smoothstep(
		-lightning_smoothness, lightning_smoothness,
		texture(tex, uv1).r - texture(tex, uv2).r
	);
}

float fresnel(float amount, vec3 normal, vec3 view)
{
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0 )), amount);
}

void fragment()
{
	float x = UV.x * 2.0 - 1.0;
	float y = UV.y * 2.0 - 1.0;
	float r = sqrt(pow(x, 2) + pow(y, 2));
	
	if (r > 1.0) {
		// Set transparency outside of the radius
		COLOR = vec4(0.0);
	} else {
		float z = sqrt(1.0 - pow(r, 2));
		// "Fake" normal vector calculated using the position on the quad
		vec3 normal = vec3(x, y, z);
		// "Fake" view vector, always +Z axis
		vec3 view = vec3(0.0, 0.0, 1.0);
		
		vec2 base_uv1 = UV * 0.5 + vec2(TIME * speed, offset);
		vec2 base_uv2 = UV * 0.5 + vec2(0.1 + offset, TIME * speed);
		float center = sample_both_tex(noise_texture, base_uv1, base_uv2);
		float lightning = clamp((0.5 - abs(center - 0.5)) * 1.5, 0.0, 1.0);
		
		float basic_fresnel = fresnel(4.0, normal, view);
		basic_fresnel = clamp(basic_fresnel * 2.0 + lightning * 0.7, 0.0, 1.0);
		COLOR = color * basic_fresnel * 1.4;
		COLOR.a = basic_fresnel;
	}
}
