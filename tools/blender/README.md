# Blender-Skripte

`build_ninja.py` erzeugt die Spielfigur (Mesh, Skelett, sieben Animationen) und exportiert sie nach
`assets/characters/ninja/ninja.glb`. Das Modell ist komplett eigenes Werk.

## Neu erzeugen
```
python -m venv .venv && .venv/bin/pip install bpy      # Blender als Python-Modul (Blender 5.x, Python 3.13)
.venv/bin/python tools/blender/build_ninja.py assets/characters/ninja/ninja.glb [vorschau-ordner]
```
Mit Vorschau-Ordner werden Bilder einzelner Posen gerendert (Cycles auf der CPU, ein paar Sekunden je Bild).
Danach in Godot importieren (`godot --headless --path . --import`) und Tests laufen lassen.

## Konventionen
- Maße in Metern, Füße bei z = 0, Körpergröße etwa 1,45 m (Chibi). Blickrichtung im Blender-Raum +Y (wird im glTF zu -Z, wie Godot es erwartet).
- Animationsnamen mit Endung `-loop` wiederholt Godot beim Import (ohne Endung: einmalig). Die Endung verschwindet beim Import: im Spiel heißen die Clips `idle`, `run`, `sneak`, `sneak_idle`, `jump`, `fall`, `land`.
- Die Namen stehen in `gameplay/animation_logic.gd`; neue Clips dort und im Skript (`CLIPS`) ergänzen.
- Die `.glb` liegt in Git LFS (`assets/**/*.glb`).
