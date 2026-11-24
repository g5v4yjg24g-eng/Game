// Cartoon-Schattierung: drei Stufen (Schatten, Mitte, Licht) mit harten Kanten, keine Texturen.
// Farbe kommt aus `albedo`; die Schattenstufe bleibt das Umgebungslicht der Szene, Mitte und Licht
// kommen vom Sonnenlicht. Kompatibel mit dem Mobile-Renderer.
shader_type spatial;
render_mode specular_disabled;

uniform vec4 albedo : source_color = vec4(1.0);
// Ab diesem Wert (Licht auf der Fläche, 0 bis 1) beginnt die Mittelstufe, ab `light_threshold` die Lichtstufe.
uniform float mid_threshold : hint_range(0.0, 1.0) = 0.15;
uniform float light_threshold : hint_range(0.0, 1.0) = 0.55;
// Helligkeit der Mittel- und Lichtstufe als Anteil des Sonnenlichts.
uniform float mid_strength : hint_range(0.0, 1.0) = 0.38;
uniform float light_strength : hint_range(0.0, 2.0) = 0.7;
// Weicher Übergang der Kanten (klein = hart). Etwas Weichheit verhindert Flimmern.
uniform float edge_softness : hint_range(0.001, 0.2) = 0.015;

void fragment() {
	ALBEDO = albedo.rgb;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
}

void light() {
	float lit = clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION;
	float mid = smoothstep(mid_threshold - edge_softness, mid_threshold + edge_softness, lit);
	float full = smoothstep(light_threshold - edge_softness, light_threshold + edge_softness, lit);
	float band = mix(0.0, mid_strength, mid);
	band = mix(band, light_strength, full);
	DIFFUSE_LIGHT += LIGHT_COLOR / PI * band;
}
