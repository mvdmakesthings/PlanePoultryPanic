// Hit flash: tints a sprite toward a solid color (Juice.flash), keeping
// its alpha so the silhouette stays. flash runs 0 (normal) to 1 (solid).
shader_type canvas_item;

uniform vec4 flash_color : source_color = vec4(1.0);
uniform float flash : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 base = texture(TEXTURE, UV) * COLOR;
	COLOR = vec4(mix(base.rgb, flash_color.rgb, flash), base.a);
}
