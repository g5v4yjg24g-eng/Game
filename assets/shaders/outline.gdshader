// Cartoon-Umriss per "Inverted Hull": Das Netz wird entlang seiner (geglätteten) Normalen aufgebläht
// und nur die Rückseiten werden einfarbig gezeichnet. Die Breite wächst mit dem Abstand zur Kamera,
// damit die Linie am Bildschirm ähnlich dick bleibt. Kompatibel mit dem Mobile-Renderer.
shader_type spatial;
render_mode cull_front, unshaded;

uniform vec4 outline_color : source_color = vec4(0.04, 0.04, 0.07, 1.0);
// Breite in Metern bei `reference_distance`: 0,05 m sind etwa 4 bis 5 Pixel bei 1280 x 590.
uniform float width = 0.05;
uniform float reference_distance = 5.0;
uniform float min_scale = 0.6;
uniform float max_scale = 4.0;

void vertex() {
	float depth = max(-(MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).z, 0.1);
	float scale = clamp(depth / reference_distance, min_scale, max_scale);
	// COLOR.r = Breitenfaktor je Punkt (dünne Teile der Figur); ohne Farbe ist COLOR weiß, also 1.
	VERTEX += normalize(NORMAL) * width * scale * COLOR.r;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
