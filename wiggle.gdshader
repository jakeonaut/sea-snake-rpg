/* 
Earthbound battle backgrounds shader with scrolling effect and palette cycling like in the original game.
@retr0_dev
	
Apply the shader to a TextureRect or a Sprite. Use a texture with some shapes in a transparent background for best results.
You can then use a ColorRect or another method to paint the background.
You can use the shader on multiple TextureRects and obtain a double-buffer effect tweaking the values for each one, remember to Make Unique the shader material.
*/
shader_type canvas_item;

uniform float screen_height = 512.0;
uniform float amplitude = 0.075;
uniform float frequency = 10.0;
uniform float speed = 2.0;
uniform float amplitude_vertical = 0.0;
uniform float frequency_vertical = 0.0;
uniform float speed_vertical = 0.0;
uniform vec2 scroll_direction = vec2(0.0, 0.0);
uniform float scrolling_speed = 0.08;

void fragment()
{
	float diff_x = amplitude * sin((frequency * SCREEN_UV.y) + (speed * TIME));
	float diff_y = amplitude_vertical * sin((frequency_vertical * SCREEN_UV.y)  + (speed_vertical * TIME));
	vec2 scroll = scroll_direction * TIME * scrolling_speed;
	vec4 tex = texture(SCREEN_TEXTURE, vec2(SCREEN_UV.x + diff_x, SCREEN_UV.y + diff_y) + scroll);
	
	COLOR = tex;
	// COLOR = mix(vec4(0.0), COLOR, float(int(SCREEN_UV.y * screen_height) % 2));
}