shader_type spatial;
render_mode depth_draw_opaque, unshaded, world_vertex_coords;

uniform vec4 albedo : hint_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D texture_albedo : hint_albedo;

uniform float amplitude = 0.075;
uniform float frequency = 10.0;
uniform float speed = 2.0;
uniform float amplitude_vertical = 0.0;
uniform float frequency_vertical = 0.0;
uniform float speed_vertical = 0.0;
uniform vec2 scroll_direction = vec2(0.0, 0.0);
uniform float scrolling_speed = 0.08;

void fragment() {
	vec2 base_uv = UV;

    float diff_x = amplitude * sin((frequency * UV.y) + (speed * TIME));
	float diff_y = amplitude_vertical * sin((frequency_vertical * UV.y)  + (speed_vertical * TIME));
	vec2 scroll = scroll_direction * TIME * scrolling_speed;
	vec4 tex = texture(texture_albedo, vec2(UV.x + diff_x, UV.y + diff_y) + scroll);
	ALBEDO = albedo.rgb * tex.rgb;
    ALPHA = albedo.a;
}