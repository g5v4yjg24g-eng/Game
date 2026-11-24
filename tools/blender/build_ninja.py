"""Erzeugt die Spielfigur (Mesh, Skelett, Animationen) und exportiert sie als .glb.

Aufruf (mit dem Python-Modul `bpy`, Blender 4.x oder 5.x):
    python build_ninja.py <ausgabe.glb> [vorschau-ordner]

Die Figur ist komplett eigenes Werk, ohne Fremd-Assets. Blickrichtung im Blender-Raum ist +Y;
der glTF-Export macht daraus -Z, die Blickrichtung in Godot. Maße in Metern, Füße bei z = 0,
Körpergröße etwa 1,45 m (Chibi-Proportionen: großer Kopf, kurze Beine, Zielrichtung nach dem Referenzbild
des Nutzers). Animationsnamen mit Endung "-loop" wiederholt Godot beim Import.
"""

import math
import os
import sys

import bpy  # muss vor bmesh und mathutils importiert werden
import bmesh  # noqa: E402
from mathutils import Euler, Matrix, Vector  # noqa: E402

FPS = 30

# --- Farben (Cartoon-Palette, siehe docs/STIL_CARTOON.md) --------------------------------------
MATERIALS = [
    ("stoff", (0.20, 0.20, 0.25), 0.9, 0.0),  # 0 Anthrazit: Kleidung, Kapuze
    ("rot", (0.80, 0.17, 0.15), 0.8, 0.0),  # 1 Akzent: Stirnband, Gürtel, Polster, Knieschützer
    ("haut", (0.95, 0.70, 0.42), 0.8, 0.0),  # 2 Gesicht, Fäuste
    ("hell", (0.36, 0.36, 0.42), 0.9, 0.0),  # 3 Maske, Kragen, Manschetten
    ("stahl", (0.68, 0.70, 0.75), 0.35, 0.8),  # 4 Schwert
    ("griff", (0.10, 0.08, 0.07), 0.8, 0.0),  # 5 Schwertgriff
    ("dunkel", (0.09, 0.09, 0.12), 0.85, 0.0),  # 6 Stiefel, Scheide, Hauben-Grat
    ("weiss", (0.97, 0.97, 0.97), 0.6, 0.0),  # 7 Augen
    ("schwarz", (0.02, 0.02, 0.03), 0.6, 0.0),  # 8 Pupillen, Brauen
]
STOFF, ROT, HAUT, HELL, STAHL, GRIFF, DUNKEL, WEISS, SCHWARZ = range(9)

# --- Maße (Meter, Füße bei z = 0) ---------------------------------------------------------------
THIGH_LEN = 0.26
SHIN_LEN = 0.25
LEG_STAND = THIGH_LEN + SHIN_LEN  # Hüfte bis Knöchel bei gestrecktem Bein
HIP_HEIGHT = 0.58  # Höhe des Hüftknochens im Stand
ANKLE_HEIGHT = 0.07  # Höhe des Knöchels (Fußknochen) im Stand
HEAD_CENTER = (0.0, 0.0, 1.20)
HEAD_RADII = (0.29, 0.28, 0.27)  # Kapuze: breiter als die Schultern (Chibi)
# Entwurfstempo des Laufzyklus in m/s. Muss zu RUN_SPEED in core/controls_config.gd passen,
# sonst rutschen die Füße.
RUN_SPEED = 5.2

# --- Skelett (Armature-Raum, x = rechts, y = vorn, z = oben) -------------------------------------
# name: (Elternknochen, Kopf, Ende)
BONES = {
    "root": (None, (0, 0, 0), (0, 0, 0.12)),
    "hips": ("root", (0, 0, 0.58), (0, 0, 0.64)),
    "spine": ("hips", (0, 0, 0.64), (0, 0, 0.78)),
    "chest": ("spine", (0, 0, 0.78), (0, 0, 0.95)),
    "neck": ("chest", (0, 0, 0.95), (0, 0, 1.00)),
    "head": ("neck", (0, 0, 1.00), (0, 0, 1.46)),
    # Flatternde Enden des Stirnbands (Kette aus drei Knochen, wie ein Schal)
    "band_1": ("head", (0, -0.25, 1.34), (0, -0.38, 1.35)),
    "band_2": ("band_1", (0, -0.38, 1.35), (0, -0.50, 1.33)),
    "band_3": ("band_2", (0, -0.50, 1.33), (0, -0.62, 1.29)),
}
SIDES = {"l": -1.0, "r": 1.0}  # anatomisch: links = -x bei Blick nach +y
for _n, _s in SIDES.items():
    BONES[f"upper_arm_{_n}"] = ("chest", (_s * 0.25, 0, 0.92), (_s * 0.25, 0, 0.75))
    BONES[f"forearm_{_n}"] = (f"upper_arm_{_n}", (_s * 0.25, 0, 0.75), (_s * 0.25, 0, 0.61))
    BONES[f"hand_{_n}"] = (f"forearm_{_n}", (_s * 0.25, 0, 0.61), (_s * 0.25, 0, 0.52))
    BONES[f"thigh_{_n}"] = ("hips", (_s * 0.11, 0, 0.58), (_s * 0.11, 0, 0.32))
    BONES[f"shin_{_n}"] = (f"thigh_{_n}", (_s * 0.11, 0, 0.32), (_s * 0.11, 0, 0.07))
    BONES[f"foot_{_n}"] = (f"shin_{_n}", (_s * 0.11, 0, 0.07), (_s * 0.11, 0.10, 0.03))


# --- Geometrie ---------------------------------------------------------------------------------
class MeshBuilder:
    """Sammelt alle Körperteile in einem Mesh; jedes Teil gehört voll zu einem Knochen."""

    def __init__(self):
        self.bm = bmesh.new()
        self.deform = self.bm.verts.layers.deform.verify()
        self.width_layer = self.bm.verts.layers.float.new("outline_w")
        self.groups = list(BONES.keys())
        # Breitenfaktor des Cartoon-Umrisses für alle folgenden Teile (dünne Teile: klein)
        self.outline_scale = 1.0

    def _finish(self, verts, bone, material, smooth):
        index = self.groups.index(bone)
        faces = {f for v in verts for f in v.link_faces}
        for f in faces:
            f.material_index = material
            f.smooth = smooth
        for v in verts:
            v[self.deform][index] = 1.0
            v[self.width_layer] = self.outline_scale

    def ellipsoid(self, bone, center, radii, material, smooth=True, segments=14, rings=9):
        geo = bmesh.ops.create_uvsphere(self.bm, u_segments=segments, v_segments=rings, radius=1.0)
        verts = geo["verts"]
        for v in verts:
            v.co = Vector((v.co.x * radii[0], v.co.y * radii[1], v.co.z * radii[2])) + Vector(center)
        self._finish(verts, bone, material, smooth)

    def box(self, bone, center, size, material, rot_deg=(0, 0, 0), matrix=None):
        geo = bmesh.ops.create_cube(self.bm, size=1.0)
        verts = geo["verts"]
        rot = matrix if matrix is not None else Euler([math.radians(a) for a in rot_deg], "XYZ").to_matrix()
        for v in verts:
            local = Vector((v.co.x * size[0], v.co.y * size[1], v.co.z * size[2]))
            v.co = rot @ local + Vector(center)
        self._finish(verts, bone, material, False)

    def cylinder(self, bone, center, radius, depth, material, matrix=None, smooth=True, segments=14):
        geo = bmesh.ops.create_cone(
            self.bm, cap_ends=True, cap_tris=False, segments=segments, radius1=radius, radius2=radius, depth=depth
        )
        verts = geo["verts"]
        rot = matrix if matrix is not None else Matrix.Identity(3)
        for v in verts:
            v.co = rot @ Vector(v.co) + Vector(center)
        self._finish(verts, bone, material, smooth)


    def capsule(self, bone, a, b, r1, r2, material, segments=18):
        """Kegelstumpf von a (Radius r1) nach b (Radius r2) mit runden Enden."""
        a, b = Vector(a), Vector(b)
        rot = z_aligned(a, b)
        geo = bmesh.ops.create_cone(
            self.bm, cap_ends=False, segments=segments, radius1=r1, radius2=r2, depth=(b - a).length
        )
        verts = list(geo["verts"])
        center = (a + b) / 2
        for v in verts:
            v.co = rot @ Vector(v.co) + center
        self._finish(verts, bone, material, True)
        self.ellipsoid(bone, a, (r1, r1, r1), material, segments=segments, rings=9)
        self.ellipsoid(bone, b, (r2, r2, r2), material, segments=segments, rings=9)

    def loft(self, sections, bone_centers, material, segments=16):
        """Glatter Rumpf aus Ellipsen-Querschnitten (z, rx, ry); Gewichte laufen weich zwischen Knochen."""
        rings = []
        for z, rx, ry in sections:
            ring = []
            for i in range(segments):
                ang = 2 * math.pi * i / segments
                vert = self.bm.verts.new((rx * math.sin(ang), ry * math.cos(ang), z))
                vert[self.width_layer] = self.outline_scale
                ring.append(vert)
            rings.append(ring)
        faces = []
        for r in range(len(rings) - 1):
            for i in range(segments):
                j = (i + 1) % segments
                faces.append(self.bm.faces.new((rings[r][i], rings[r][j], rings[r + 1][j], rings[r + 1][i])))
        faces.append(self.bm.faces.new(list(reversed(rings[0]))))
        faces.append(self.bm.faces.new(rings[-1]))
        bmesh.ops.recalc_face_normals(self.bm, faces=faces)
        for f in faces:
            f.material_index = material
            f.smooth = True
        names = [n for n, _ in bone_centers]
        zs = [zc for _, zc in bone_centers]
        for ring, (z, _rx, _ry) in zip(rings, sections):
            weights = {}
            if z <= zs[0]:
                weights[names[0]] = 1.0
            elif z >= zs[-1]:
                weights[names[-1]] = 1.0
            else:
                for k in range(len(zs) - 1):
                    if zs[k] <= z <= zs[k + 1]:
                        t = (z - zs[k]) / (zs[k + 1] - zs[k])
                        weights[names[k]] = 1.0 - t
                        weights[names[k + 1]] = t
            for v in ring:
                for name, w in weights.items():
                    v[self.deform][self.groups.index(name)] = w


    def cone(self, bone, a, b, r1, r2, material, segments=12):
        """Kegel(stumpf) von a (Radius r1) nach b (Radius r2), mit Deckflächen."""
        a, b = Vector(a), Vector(b)
        rot = z_aligned(a, b)
        geo = bmesh.ops.create_cone(
            self.bm, cap_ends=True, cap_tris=False, segments=segments, radius1=r1, radius2=r2, depth=(b - a).length
        )
        verts = list(geo["verts"])
        center = (a + b) / 2
        for v in verts:
            v.co = rot @ Vector(v.co) + center
        self._finish(verts, bone, material, True)


def aligned(a, b):
    """Drehung, die die y-Achse eines Quaders auf die Strecke a -> b legt."""
    d = (Vector(b) - Vector(a)).normalized()
    return Vector((0, 1, 0)).rotation_difference(d).to_matrix()


def z_aligned(a, b):
    """Drehung, die die z-Achse (Zylinder) auf die Strecke a -> b legt."""
    d = (Vector(b) - Vector(a)).normalized()
    return Vector((0, 0, 1)).rotation_difference(d).to_matrix()


def build_geometry():
    m = MeshBuilder()

    # Rumpf: kompakt, ein glatter Verlauf von der Hüfte bis zu den Schultern
    torso = [
        (0.52, 0.150, 0.110),
        (0.60, 0.175, 0.125),
        (0.68, 0.160, 0.115),
        (0.77, 0.185, 0.125),
        (0.87, 0.205, 0.130),
        (0.94, 0.190, 0.115),
        (0.98, 0.110, 0.085),
    ]
    m.loft(torso, [("hips", 0.60), ("spine", 0.72), ("chest", 0.88)], STOFF)
    # Gürtel mit Knoten
    m.ellipsoid("hips", (0, 0, 0.665), (0.175, 0.13, 0.036), ROT)
    m.ellipsoid("hips", (0, 0.135, 0.665), (0.06, 0.04, 0.05), ROT)  # Knoten
    m.box("hips", (-0.05, 0.135, 0.605), (0.045, 0.02, 0.09), ROT, rot_deg=(0, 0, 18))
    m.box("hips", (0.05, 0.135, 0.605), (0.045, 0.02, 0.09), ROT, rot_deg=(0, 0, -18))
    # Überkreuzter Wickelkragen: helle Lappen mit rotem Einsatz
    m.ellipsoid("chest", (0, 0.105, 0.90), (0.075, 0.03, 0.08), ROT)
    m.box("chest", (-0.075, 0.118, 0.855), (0.11, 0.03, 0.2), HELL, rot_deg=(0, -28, 0))
    m.box("chest", (0.075, 0.118, 0.855), (0.11, 0.03, 0.2), HELL, rot_deg=(0, 28, 0))

    # Kopf: Kapuze, Gesicht, Maske, große Augen mit Brauen, Stirnband mit Enden
    cx, cy, cz = HEAD_CENTER
    m.ellipsoid("head", HEAD_CENTER, HEAD_RADII, STOFF, segments=32, rings=20)
    m.ellipsoid("head", (0, 0.15, 1.18), (0.185, 0.14, 0.115), HAUT, segments=28, rings=16)  # Gesicht
    m.ellipsoid("head", (0, 0.14, 1.05), (0.215, 0.16, 0.085), HELL, segments=28, rings=16)  # Maske
    for side in (-1, 1):
        x = side * 0.088
        m.ellipsoid("head", (x, 0.285, 1.20), (0.068, 0.025, 0.075), WEISS)  # Auge
        m.ellipsoid("head", (x + side * 0.004, 0.303, 1.195), (0.036, 0.015, 0.045), SCHWARZ)  # Pupille
        m.ellipsoid("head", (x - side * 0.016, 0.316, 1.222), (0.013, 0.008, 0.016), WEISS)  # Glanzpunkt
        # Braue: innen tiefer (zorniger Blick)
        m.box("head", (x, 0.298, 1.275), (0.115, 0.022, 0.03), SCHWARZ, rot_deg=(0, -side * 22, 0))
    band = [
        (1.310, 0.277, 0.268),
        (1.340, 0.260, 0.251),
        (1.370, 0.237, 0.230),
    ]
    m.loft(band, [("head", 1.0)], ROT, segments=20)
    # Spitzen seitlich am Stirnband (wie in der Vorlage)
    for side in (-1, 1):
        m.cone("head", (side * 0.255, -0.02, 1.335), (side * 0.37, -0.03, 1.50), 0.055, 0.0, ROT)

    # Enden des Stirnbands (dünn: schmaler Umriss)
    m.outline_scale = 0.2
    points = [(0, -0.25, 1.34), (0, -0.38, 1.35), (0, -0.50, 1.33), (0, -0.62, 1.29)]
    widths = [0.14, 0.12, 0.10]
    for i, bone in enumerate(["band_1", "band_2", "band_3"]):
        a, b = points[i], points[i + 1]
        mid = (Vector(a) + Vector(b)) / 2
        length = (Vector(b) - Vector(a)).length
        m.box(bone, mid, (widths[i], length, 0.014), ROT, matrix=aligned(a, b))
        m.box(bone, mid, (0.014, length, widths[i] * 0.75), ROT, matrix=aligned(a, b))
    m.outline_scale = 1.0

    # Arme und Beine: kräftig und kurz, Fäuste in Hautfarbe, rote Polster
    for n, side in SIDES.items():
        x = side * 0.25
        m.capsule(f"upper_arm_{n}", (x, 0, 0.91), (x, 0, 0.76), 0.070, 0.060, STOFF)
        m.ellipsoid(f"upper_arm_{n}", (side * 0.27, 0, 0.955), (0.095, 0.085, 0.065), ROT)  # Schulterpolster
        m.capsule(f"forearm_{n}", (x, 0, 0.76), (x, 0, 0.625), 0.060, 0.052, STOFF)
        m.ellipsoid(f"forearm_{n}", (x, 0, 0.64), (0.064, 0.064, 0.02), HELL)  # Manschette
        m.ellipsoid(f"hand_{n}", (x, 0.015, 0.555), (0.080, 0.080, 0.080), HAUT)  # Faust
        x = side * 0.11
        m.capsule(f"thigh_{n}", (x, 0, 0.57), (x, 0, 0.34), 0.092, 0.078, STOFF)
        m.capsule(f"shin_{n}", (x, 0, 0.32), (x, 0, 0.11), 0.076, 0.062, STOFF)
        m.ellipsoid(f"shin_{n}", (x, 0.045, 0.30), (0.078, 0.055, 0.07), ROT)  # Knieschützer
        m.ellipsoid(f"foot_{n}", (x, 0.045, 0.058), (0.085, 0.145, 0.062), DUNKEL)  # Stiefel

    # Schwert auf dem Rücken: Griff über der rechten Schulter, Scheide nach links unten (dünn)
    m.outline_scale = 0.3
    top = Vector((0.10, -0.165, 1.08))
    guard = Vector((0.075, -0.165, 0.99))
    tip = Vector((-0.15, -0.165, 0.46))
    m.cylinder("chest", (top + guard) / 2, 0.018, (top - guard).length, GRIFF, matrix=z_aligned(guard, top))
    m.cylinder("chest", guard, 0.05, 0.014, STAHL, matrix=z_aligned(guard, top))  # Stichblatt
    m.box("chest", (guard + tip) / 2, (0.052, (tip - guard).length, 0.038), DUNKEL, matrix=aligned(guard, tip))
    m.outline_scale = 1.0

    mesh = bpy.data.meshes.new("NinjaMesh")
    m.bm.to_mesh(mesh)
    m.bm.free()
    obj = bpy.data.objects.new("Ninja", mesh)
    bpy.context.scene.collection.objects.link(obj)
    for name in m.groups:
        obj.vertex_groups.new(name=name)
    for _n, mat, rough, metal in MATERIALS:
        material = bpy.data.materials.new(_n)
        material.use_nodes = True
        bsdf = material.node_tree.nodes["Principled BSDF"]
        bsdf.inputs["Base Color"].default_value = (*mat, 1.0)
        bsdf.inputs["Roughness"].default_value = rough
        bsdf.inputs["Metallic"].default_value = metal
        mesh.materials.append(material)
    return obj


def build_outline(mesh_obj):
    """Zweites Mesh für den Cartoon-Umriss: gleiche Form, aber überall geglättete Normale.

    Godot zeichnet es mit einem Shader, der die Fläche entlang der Normale aufbläht und nur die
    Rückseiten zeigt (Inverted Hull). Mit geglätteten Normalen entstehen an Kanten keine Lücken.
    Das Mesh hängt am selben Skelett und bewegt sich mit.
    """
    mesh = mesh_obj.data.copy()
    mesh.name = "NinjaUmrissMesh"
    mesh.materials.clear()
    material = bpy.data.materials.new("umriss")
    material.use_nodes = True
    material.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.04, 0.04, 0.07, 1.0)
    mesh.materials.append(material)
    for poly in mesh.polygons:
        poly.material_index = 0
        poly.use_smooth = True
    normals = [tuple(mesh.vertex_normals[loop.vertex_index].vector) for loop in mesh.loops]
    mesh.normals_split_custom_set(normals)
    # Breitenfaktor je Punkt als Vertexfarbe (Rot-Kanal): der Umriss-Shader skaliert damit seine Breite
    factor = mesh.attributes["outline_w"]
    colors = mesh.color_attributes.new("Breite", "FLOAT_COLOR", "POINT")
    for i, item in enumerate(colors.data):
        w = factor.data[i].value
        item.color = (w, w, w, 1.0)
    mesh.color_attributes.active_color = colors
    obj = bpy.data.objects.new("NinjaUmriss", mesh)
    bpy.context.scene.collection.objects.link(obj)
    for group in mesh_obj.vertex_groups:
        obj.vertex_groups.new(name=group.name)
    return obj


def build_armature():
    arm = bpy.data.armatures.new("NinjaSkelett")
    obj = bpy.data.objects.new("NinjaSkelett", arm)
    bpy.context.scene.collection.objects.link(obj)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.mode_set(mode="EDIT")
    for name, (parent, head, tail) in BONES.items():
        bone = arm.edit_bones.new(name)
        bone.head = Vector(head)
        bone.tail = Vector(tail)
        if parent:
            bone.parent = arm.edit_bones[parent]
    bpy.ops.object.mode_set(mode="OBJECT")
    return obj


# --- Animationen -------------------------------------------------------------------------------
class Rig:
    def __init__(self, arm_obj):
        self.obj = arm_obj
        self.rest = {n: arm_obj.data.bones[n].matrix_local.to_3x3() for n in BONES}
        for pb in arm_obj.pose.bones:
            pb.rotation_mode = "QUATERNION"

    def key(self, frame, pose):
        """pose: Knochen -> (x, y, z) Grad im Armature-Raum, optional mit Verschiebung (dx, dy, dz)."""
        for name, value in pose.items():
            rot = value[0] if isinstance(value[0], (tuple, list)) else value
            loc = value[1] if isinstance(value[0], (tuple, list)) else None
            pb = self.obj.pose.bones[name]
            r = self.rest[name]
            g = Euler([math.radians(a) for a in rot], "XYZ").to_matrix()
            pb.rotation_quaternion = (r.inverted() @ g @ r).to_quaternion()
            pb.keyframe_insert("rotation_quaternion", frame=frame)
            if loc is not None:
                pb.location = r.inverted() @ Vector(loc)
                pb.keyframe_insert("location", frame=frame)

    def clip(self, name, frames, pose_fn, loop=True):
        action = bpy.data.actions.new(name)
        action.use_fake_user = True
        if self.obj.animation_data is None:
            self.obj.animation_data_create()
        self.obj.animation_data.action = action
        for f in range(frames + 1):
            self.key(f, pose_fn(f / frames))
        return action


def leg_drop(thigh, knee):
    """Senkrechter Abstand Hüfte -> Knöchel für Oberschenkelwinkel und Kniewinkel (Grad)."""
    a = math.radians(thigh)
    return THIGH_LEN * math.cos(a) + SHIN_LEN * math.cos(a - math.radians(knee))


def legs(thigh_l, knee_l, thigh_r, knee_r, stand=LEG_STAND):
    """Beinposen und Hüfthöhe so, dass der tiefere Fuß den Boden berührt (grobe Erdung)."""
    dz = max(leg_drop(thigh_l, knee_l), leg_drop(thigh_r, knee_r)) - stand
    pose = {}
    for n, th, kn in (("l", thigh_l, knee_l), ("r", thigh_r, knee_r)):
        pose[f"thigh_{n}"] = (th, 0, 0)
        pose[f"shin_{n}"] = (-kn, 0, 0)
        foot = (kn - th) - 0.25 * max(0.0, -th)
        pose[f"foot_{n}"] = (foot, 0, 0)
    return pose, dz


def scarf(a1, a2, a3, sway=0.0):
    """Enden des Stirnbands (Knochen band_1 bis band_3)."""
    return {
        "band_1": (a1, 0, sway),
        "band_2": (a2, 0, sway * 1.3),
        "band_3": (a3, 0, sway * 1.6),
    }


def hips_pose(dz, pitch=0.0, yaw=0.0, roll=0.0, dy=0.0):
    return {"hips": ((pitch, roll, yaw), (0, dy, dz))}


def idle_pose(t):
    p = 2 * math.pi * t
    breathe = math.sin(p)
    pose = {}
    legs_pose, dz = legs(3, 6, -3, 6)
    pose.update(legs_pose)
    pose.update(hips_pose(dz + 0.004 * breathe, roll=1.0 * math.sin(p)))
    pose["spine"] = (-2 + 1.2 * breathe, 0, 0)
    pose["chest"] = (-1 + 1.5 * breathe, 0, 1.5 * math.sin(p))
    pose["head"] = (2 - 1.0 * breathe, 0, 3 * math.sin(p + 0.7))
    pose["upper_arm_l"] = (4 + 1.5 * breathe, 0, -6)
    pose["upper_arm_r"] = (-2 - 1.5 * breathe, 0, 6)
    pose["forearm_l"] = (16 + 2 * breathe, 0, 0)
    pose["forearm_r"] = (18 - 2 * breathe, 0, 0)
    pose["hand_l"] = (4, 0, 0)
    pose["hand_r"] = (4, 0, 0)
    pose.update(scarf(2 + 2 * math.sin(p), 4 + 3 * math.sin(p - 0.6), 6 + 4 * math.sin(p - 1.2), 4 * math.sin(p)))
    return pose


# --- Laufzyklus mit Fußführung (Zwei-Gelenk-Berechnung) ----------------------------------------
RUN_FRAMES = 16  # Bilder je Zyklus (beide Schritte), 0,53 s
RUN_CYCLE_SECONDS = RUN_FRAMES / FPS
RUN_CONTACT_SECONDS = 0.07  # Bodenkontakt je Fuß
RUN_STANCE = RUN_CONTACT_SECONDS / RUN_CYCLE_SECONDS  # Anteil des Zyklus im Stand
RUN_STRIDE_HALF = RUN_SPEED * RUN_CONTACT_SECONDS / 2  # Fuß vor und hinter der Hüfte im Stand
RUN_LIFT = 0.05  # Fußhöhe in der Schwungphase (niedrig: Kniebeugung bleibt unter etwa 75 Grad)
RUN_TANGENT = 0.2  # Anteil der Standgeschwindigkeit, der in die Schwungkurve übergeht
RUN_DZ_STAND = -0.04  # Hüfte beim Aufsetzen und Abdrücken (relativ zum Stand)
RUN_DZ_COMPRESS = 0.01  # zusätzliches Einfedern in der Mitte der Standphase
RUN_DZ_FLIGHT = 0.01  # Anheben in der Flugphase


def leg_ik(y, z_rel):
    """Beinwinkel für einen Knöchel an (y, z_rel) relativ zur Hüfte in der Seitenebene.

    y: nach vorn positiv, z_rel: negativ unter der Hüfte. Rückgabe: (Oberschenkel, Kniebeugung,
    erreicht) in Grad; "erreicht" ist False, wenn das Ziel zu weit weg war und gekürzt wurde.
    """
    reach = THIGH_LEN + SHIN_LEN - 1e-4
    d = math.hypot(y, z_rel)
    ok = d <= reach
    d = min(d, reach)
    cos_knee = (THIGH_LEN**2 + SHIN_LEN**2 - d**2) / (2 * THIGH_LEN * SHIN_LEN)
    flex = math.pi - math.acos(max(-1.0, min(1.0, cos_knee)))
    base = math.atan2(y, -z_rel)
    cos_hip = (THIGH_LEN**2 + d**2 - SHIN_LEN**2) / (2 * THIGH_LEN * d)
    thigh = base + math.acos(max(-1.0, min(1.0, cos_hip)))
    return math.degrees(thigh), math.degrees(flex), ok


def leg_foot(thigh_deg, flex_deg):
    """Vorwärtsrechnung (Gegenprobe): Knöchelposition (y, z) relativ zur Hüfte."""
    a = math.radians(thigh_deg)
    b = a - math.radians(flex_deg)
    return (
        THIGH_LEN * math.sin(a) + SHIN_LEN * math.sin(b),
        -(THIGH_LEN * math.cos(a) + SHIN_LEN * math.cos(b)),
    )


def run_foot(u):
    """Knöchelweg eines Fußes über den Zyklus (u = 0 bis 1, 0 = Aufsetzen): (y, z, im Stand?).

    Stand: Der Fuß liegt auf dem Boden und wandert mit genau der Laufgeschwindigkeit nach hinten
    (kein Rutschen). Schwung: Hermite-Kurve zurück nach vorn mit angehobenem Fuß.
    """
    s = RUN_STANCE
    if u < s:
        tau = u / s
        return RUN_STRIDE_HALF * (1.0 - 2.0 * tau), ANKLE_HEIGHT, True
    tau = (u - s) / (1.0 - s)
    duration = (1.0 - s) * RUN_CYCLE_SECONDS
    p0, p1 = -RUN_STRIDE_HALF, RUN_STRIDE_HALF
    m = -RUN_SPEED * duration * RUN_TANGENT
    h00, h10 = 2 * tau**3 - 3 * tau**2 + 1, tau**3 - 2 * tau**2 + tau
    h01, h11 = -2 * tau**3 + 3 * tau**2, tau**3 - tau**2
    y = h00 * p0 + h10 * m + h01 * p1 + h11 * m
    z = ANKLE_HEIGHT + RUN_LIFT * math.sin(math.pi * tau) ** 0.9
    return y, z, False


def run_hips_dz(u):
    """Hüfthöhe: in der Standphase eines Beins eingefedert, in der Flugphase leicht angehoben."""
    s = RUN_STANCE
    u_leg = u % 0.5 * 1.0  # beide Beine wechseln sich ab: Halbzyklus
    half = 0.5
    if u_leg < s:
        return RUN_DZ_STAND - RUN_DZ_COMPRESS * math.sin(math.pi * u_leg / s)
    flight = (u_leg - s) / (half - s)
    return RUN_DZ_STAND + RUN_DZ_FLIGHT * math.sin(math.pi * flight)


def run_legs(u):
    """Winkel beider Beine und Hüfthöhe: {l: (thigh, flex, im Stand?, erreicht?)}, dz."""
    dz = run_hips_dz(u)
    legs_out = {}
    for name, offset in (("l", 0.0), ("r", 0.5)):
        y, z, stance = run_foot((u + offset) % 1.0)
        z_rel = z - (HIP_HEIGHT + dz)
        thigh, flex, reached = leg_ik(y, z_rel)
        legs_out[name] = (thigh, flex, stance, reached, y)
    return legs_out, dz


def run_pose(t):
    p = 2 * math.pi * t
    legs_out, dz = run_legs(t)
    pose = {}
    for name, (thigh, flex, stance, _reached, _y) in legs_out.items():
        pose[f"thigh_{name}"] = (thigh, 0, 0)
        pose[f"shin_{name}"] = (-flex, 0, 0)
        # Fuß flach im Stand, in der Schwungphase leicht nach unten gestreckt
        foot = (flex - thigh) + (0.0 if stance else -18.0)
        pose[f"foot_{name}"] = (foot, 0, 0)
    pose.update(hips_pose(dz, yaw=5 * math.sin(p), roll=2.5 * math.sin(p)))
    pose["spine"] = (-8, 0, -5 * math.sin(p))
    pose["chest"] = (-6, 0, -5 * math.sin(p))
    pose["head"] = (12, 0, 1.5 * math.sin(p))
    # Arme gegenläufig zu den Beinen: linker Arm hinten, wenn das linke Bein vorn aufsetzt
    for name, sign in (("l", -1.0), ("r", 1.0)):
        swing = sign * 52 * math.cos(p)
        pose[f"upper_arm_{name}"] = (swing + 4, 0, -7 if name == "l" else 7)
        pose[f"forearm_{name}"] = (88 + 14 * sign * math.cos(p), 0, 0)
        pose[f"hand_{name}"] = (6, 0, 0)
    # Schal: weht fast waagerecht nach hinten, Welle läuft zum Ende hin
    pose.update(
        scarf(
            -4 + 7 * math.sin(2 * p),
            -8 + 9 * math.sin(2 * p - 0.9),
            -8 + 11 * math.sin(2 * p - 1.8),
            6 * math.sin(p),
        )
    )
    return pose


def run_report():
    """Prüfzahlen des Laufzyklus: Rutschen, Reichweite, Kniebeugung, Körperauf und -ab."""
    n = 170
    clamped = 0
    flex_min, flex_max = 999.0, 0.0
    dz_min, dz_max = 999.0, -999.0
    max_err = 0.0
    stance_speeds = []
    previous = None
    for i in range(n + 1):
        u = i / n
        legs_out, dz = run_legs(u)
        dz_min, dz_max = min(dz_min, dz), max(dz_max, dz)
        for name, (thigh, flex, stance, reached, y) in legs_out.items():
            clamped += 0 if reached else 1
            flex_min, flex_max = min(flex_min, flex), max(flex_max, flex)
            fy, _fz = leg_foot(thigh, flex)
            if reached:
                max_err = max(max_err, abs(fy - y))
        # Standfuß: Geschwindigkeit des Knöchels relativ zur Hüfte
        l_thigh, l_flex, l_stance, _r, _y = legs_out["l"]
        fy_now, _ = leg_foot(l_thigh, l_flex)
        if previous is not None and previous[1] and l_stance:
            stance_speeds.append(-(fy_now - previous[0]) / (RUN_CYCLE_SECONDS / n))
        previous = (fy_now, l_stance)
    avg = sum(stance_speeds) / len(stance_speeds) if stance_speeds else 0.0
    print(
        "Laufzyklus: Zyklus %.2f s, Kontakt %.2f s, Standfuß %.2f m/s (Soll %.1f), "
        "Kniebeugung %.0f bis %.0f Grad, Hüfte %.1f bis %.1f cm, nicht erreicht: %d, FK-Abweichung %.4f m"
        % (RUN_CYCLE_SECONDS, RUN_CONTACT_SECONDS, avg, RUN_SPEED, flex_min, flex_max,
           dz_min * 100, dz_max * 100, clamped, max_err)
    )


def sneak_pose(t):
    p = 2 * math.pi * t
    pose = {}
    thighs, knees = {}, {}
    for n, off in (("l", 0.0), ("r", math.pi)):
        th = p + off
        thighs[n] = 24 * math.sin(th) + 44
        knees[n] = 62 + 24 * max(0.0, math.cos(th - 0.35))
    legs_pose, dz = legs(thighs["l"], knees["l"], thighs["r"], knees["r"])
    pose.update(legs_pose)
    pose.update(hips_pose(dz, pitch=-4, yaw=4 * math.sin(p)))
    pose["spine"] = (-20, 0, -3 * math.sin(p))
    pose["chest"] = (-12, 0, -3 * math.sin(p))
    pose["head"] = (24, 0, 0)
    for n, off in (("l", math.pi), ("r", 0.0)):
        th = p + off
        pose[f"upper_arm_{n}"] = (-12 * math.sin(th) + 10, 0, -10 if n == "l" else 10)
        pose[f"forearm_{n}"] = (62, 0, 0)
        pose[f"hand_{n}"] = (5, 0, 0)
    pose.update(scarf(-8 + 4 * math.sin(2 * p), -4 + 5 * math.sin(2 * p - 0.5), 0 + 6 * math.sin(2 * p - 1.0), 3 * math.sin(p)))
    return pose


def sneak_idle_pose(t):
    p = 2 * math.pi * t
    breathe = math.sin(p)
    legs_pose, dz = legs(40, 66, 30, 58)
    pose = dict(legs_pose)
    pose.update(hips_pose(dz + 0.004 * breathe, pitch=-4))
    pose["spine"] = (-20 + 1.5 * breathe, 0, 0)
    pose["chest"] = (-12 + 1.5 * breathe, 0, 2 * math.sin(p))
    pose["head"] = (24 - 1.0 * breathe, 0, 5 * math.sin(p + 0.7))
    pose["upper_arm_l"] = (10, 0, -10)
    pose["upper_arm_r"] = (10, 0, 10)
    pose["forearm_l"] = (62, 0, 0)
    pose["forearm_r"] = (62, 0, 0)
    pose.update(scarf(-6 + 2 * math.sin(p), -2 + 3 * math.sin(p - 0.6), 2 + 4 * math.sin(p - 1.2), 3 * math.sin(p)))
    return pose


def smooth(t):
    return t * t * (3 - 2 * t)


def jump_pose(t):
    """Absprung: aus der Hocke strecken, Arme nach oben (einmalig)."""
    s = smooth(t)
    pose = {}
    th_l, kn_l = 38 * (1 - s) + 24 * s, 70 * (1 - s) + 40 * s
    th_r, kn_r = 30 * (1 - s) + 6 * s, 62 * (1 - s) + 20 * s
    legs_pose, dz = legs(th_l, kn_l, th_r, kn_r)
    pose.update(legs_pose)
    pose.update(hips_pose(dz * (1 - s) + 0.04 * s, pitch=-4 * (1 - s)))
    pose["spine"] = (-18 * (1 - s) + 2 * s, 0, 0)
    pose["chest"] = (-10 * (1 - s) + 4 * s, 0, 0)
    pose["head"] = (20 * (1 - s) - 6 * s, 0, 0)
    arm = 15 * (1 - s) + 115 * s
    pose["upper_arm_l"] = (arm, 0, -12 * s)
    pose["upper_arm_r"] = (arm, 0, 12 * s)
    pose["forearm_l"] = (40 - 20 * s, 0, 0)
    pose["forearm_r"] = (40 - 20 * s, 0, 0)
    pose.update(scarf(-10 + 14 * s, -4 + 10 * s, 0 + 8 * s))
    return pose


def fall_pose(t):
    p = 2 * math.pi * t
    pose = {}
    legs_pose, _ = legs(30 + 4 * math.sin(p), 52, -12 + 4 * math.sin(p + 1), 38)
    pose.update(legs_pose)
    pose.update(hips_pose(0.03, pitch=-2))
    pose["spine"] = (2, 0, 0)
    pose["chest"] = (3 + 1.5 * math.sin(p), 0, 0)
    pose["head"] = (-4, 0, 0)
    pose["upper_arm_l"] = (120 + 6 * math.sin(p), 0, -35)
    pose["upper_arm_r"] = (112 + 6 * math.sin(p + 1), 0, 35)
    pose["forearm_l"] = (22, 0, 0)
    pose["forearm_r"] = (26, 0, 0)
    pose.update(scarf(28 + 8 * math.sin(2 * p), 24 + 10 * math.sin(2 * p - 0.5), 20 + 12 * math.sin(2 * p - 1.0), 6 * math.sin(p)))
    return pose


def land_pose(t):
    """Landung: tief abfedern und wieder aufrichten."""
    k = math.sin(math.pi * min(1.0, t * 1.15)) ** 1.2
    legs_pose, dz = legs(10 + 40 * k, 14 + 72 * k, 6 + 34 * k, 10 + 66 * k)
    pose = dict(legs_pose)
    pose.update(hips_pose(dz, pitch=-6 * k))
    pose["spine"] = (-4 - 16 * k, 0, 0)
    pose["chest"] = (-2 - 8 * k, 0, 0)
    pose["head"] = (4 + 14 * k, 0, 0)
    pose["upper_arm_l"] = (35 * (1 - k) + 14 * k, 0, -16)
    pose["upper_arm_r"] = (35 * (1 - k) + 14 * k, 0, 16)
    pose["forearm_l"] = (24 + 30 * k, 0, 0)
    pose["forearm_r"] = (24 + 30 * k, 0, 0)
    pose.update(scarf(8 - 14 * k, 6 - 10 * k, 4 - 6 * k))
    return pose


CLIPS = [
    ("idle-loop", 60, idle_pose, True),
    ("run-loop", RUN_FRAMES, run_pose, True),
    ("sneak-loop", 36, sneak_pose, True),
    ("sneak_idle-loop", 60, sneak_idle_pose, True),
    ("jump", 10, jump_pose, False),
    ("fall-loop", 24, fall_pose, True),
    ("land", 9, land_pose, False),
]


def build_actions(rig):
    return {name: rig.clip(name, frames, fn, loop) for name, frames, fn, loop in CLIPS}


# --- Vorschau und Export ----------------------------------------------------------------------
def setup_render(width, height):
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.view_settings.view_transform = "Standard"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 20
    scene.render.resolution_x = width
    scene.render.resolution_y = height
    world = bpy.data.worlds.new("Welt")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (0.42, 0.5, 0.58, 1)
    scene.world = world
    sun = bpy.data.lights.new("Sonne", "SUN")
    sun.energy = 3.5
    sun_obj = bpy.data.objects.new("Sonne", sun)
    sun_obj.rotation_euler = (math.radians(55), 0, math.radians(35))
    bpy.context.scene.collection.objects.link(sun_obj)
    fill = bpy.data.lights.new("Fuell", "AREA")
    fill.energy = 250
    fill_obj = bpy.data.objects.new("Fuell", fill)
    fill_obj.location = (-3, 3, 2.5)
    bpy.context.scene.collection.objects.link(fill_obj)
    cam_data = bpy.data.cameras.new("Kamera")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = 1.9
    cam = bpy.data.objects.new("Kamera", cam_data)
    bpy.context.scene.collection.objects.link(cam)
    scene.camera = cam
    floor = bpy.data.meshes.new("Boden")
    fb = bmesh.new()
    bmesh.ops.create_cube(fb, size=1.0)
    for v in fb.verts:
        v.co = Vector((v.co.x * 6, v.co.y * 6, v.co.z * 0.02 - 0.01))
    fb.to_mesh(floor)
    fb.free()
    floor_obj = bpy.data.objects.new("Boden", floor)
    mat = bpy.data.materials.new("BodenMat")
    mat.use_nodes = True
    mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.3, 0.32, 0.28, 1)
    floor.materials.append(mat)
    bpy.context.scene.collection.objects.link(floor_obj)
    return cam


VIEWS = {
    "seite": ((5.0, 0.0, 0.74), (90, 0, 90)),
    "vorn": ((0.0, 5.0, 0.74), (90, 0, 180)),
    "hinten": ((0.0, -5.0, 0.74), (90, 0, 0)),
}


def render_pose(rig, cam, action, frame, view, path):
    rig.obj.animation_data.action = action
    bpy.context.scene.frame_set(frame)
    location, rotation = VIEWS[view]
    cam.location = location
    cam.rotation_euler = [math.radians(a) for a in rotation]
    bpy.context.scene.render.filepath = path
    bpy.ops.render.render(write_still=True)


def make_previews(rig, actions, folder):
    os.makedirs(folder, exist_ok=True)
    for obj in bpy.data.objects:
        if obj.name == "NinjaUmriss":
            obj.hide_render = True
    cam = setup_render(330, 420)
    shots = [
        ("idle-loop", 0, "vorn"),
        ("idle-loop", 0, "seite"),
        ("idle-loop", 0, "hinten"),
        ("run-loop", 0, "seite"),
        ("run-loop", 3, "seite"),
        ("run-loop", 5, "seite"),
        ("run-loop", 8, "seite"),
        ("run-loop", 11, "seite"),
        ("run-loop", 14, "seite"),
        ("sneak-loop", 0, "seite"),
        ("sneak-loop", 18, "seite"),
        ("sneak_idle-loop", 0, "vorn"),
        ("jump", 0, "seite"),
        ("jump", 10, "seite"),
        ("fall-loop", 0, "seite"),
        ("land", 4, "seite"),
    ]
    for i, (name, frame, view) in enumerate(shots):
        render_pose(rig, cam, actions[name], frame, view, os.path.join(folder, f"{i:02d}_{name}_{frame}_{view}.png"))


def export_glb(path):
    bpy.ops.object.select_all(action="DESELECT")
    bpy.ops.export_scene.gltf(
        filepath=path,
        export_format="GLB",
        export_yup=True,
        export_apply=False,
        export_skins=True,
        export_animations=True,
        export_animation_mode="ACTIONS",
        export_force_sampling=True,
        export_optimize_animation_size=True,
        export_materials="EXPORT",
        export_vertex_color="ACTIVE",
        export_cameras=False,
        export_lights=False,
    )


def main():
    args = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else sys.argv[1:]
    out = args[0]
    preview = args[1] if len(args) > 1 else None

    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.fps = FPS
    mesh_obj = build_geometry()
    arm_obj = build_armature()
    mesh_obj.parent = arm_obj
    modifier = mesh_obj.modifiers.new("Skelett", "ARMATURE")
    modifier.object = arm_obj
    outline_obj = build_outline(mesh_obj)
    outline_obj.parent = arm_obj
    outline_mod = outline_obj.modifiers.new("Skelett", "ARMATURE")
    outline_mod.object = arm_obj

    bpy.context.view_layer.objects.active = arm_obj
    bpy.ops.object.mode_set(mode="POSE")
    rig = Rig(arm_obj)
    actions = build_actions(rig)
    bpy.ops.object.mode_set(mode="OBJECT")

    run_report()
    if preview:
        make_previews(rig, actions, preview)
    export_glb(out)
    tris = sum(len(p.vertices) - 2 for p in mesh_obj.data.polygons)
    print(f"Fertig: {out} – {len(mesh_obj.data.vertices)} Punkte, {tris} Dreiecke (Umriss-Mesh zusätzlich), {len(actions)} Animationen")


main()
