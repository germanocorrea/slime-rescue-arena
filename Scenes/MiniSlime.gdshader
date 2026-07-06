//shader_type canvas_item;
//
//void vertex() {
	//// Called for every vertex the material is visible on.
//}
//
//void fragment() {
	//// Called for every pixel the material is visible on.
//}
//
////void light() {
////	// Called for every pixel for every light affecting the CanvasItem.
////	// Uncomment to replace the default light processing function with this one.
////}


shader_type canvas_item;

uniform vec4 old_color_1 : source_color = vec4(0.388, 0.608, 1.0, 1.0);
uniform vec4 old_color_2 : source_color = vec4(0.357, 0.431, 0.882, 1.0);

uniform vec4 new_color_1 : source_color;
uniform vec4 new_color_2 : source_color;

void fragment()
{
	vec4 tex = texture(TEXTURE, UV);

	if (distance(tex.rgb, old_color_1.rgb) < 0.01)
	{
		tex.rgb = new_color_1.rgb;
	}
	else if (distance(tex.rgb, old_color_2.rgb) < 0.01)
	{
		tex.rgb = new_color_2.rgb;
	}

	COLOR = tex;
}
