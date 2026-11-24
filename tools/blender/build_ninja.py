"""Erzeugt die Spielfigur (Mesh, Skelett, Animationen) und exportiert sie als .glb.

Aufruf (mit dem Python-Modul `bpy`, Blender 4.x oder 5.x):
    python build_ninja.py <ausgabe.glb> [vorschau-ordner]

Die Figur ist komplett eigenes Werk, ohne Fremd-Assets. Blickrichtung im Blender-Raum ist +Y;
der glTF-Export macht daraus -Z, die Blickrichtung in Godot. Maße in Metern, Füße bei z = 0,
Körpergröße etwa 1,8 m. Animationsnamen mit Endung "-loop" wiederholt Godot beim Import.
"""

import math
import os
import sys

import bpy  # muss vor bmesh und mathutils importiert werden
import bmesh  # noqa: E402
from mathutils import Euler, Matrix, Vector  # noqa: E402

FPS = 30

# --- Farben ------------------------------------------------------------------------------------
MATERIALS = [
    ("stoff", (0.045, 0.05, 0.10), 0.85, 0.0),  # 0 dunkelblauer Stoff
    ("rot", (0.62, 0.09, 0.07), 0.75, 0.0),  # 1 Schal und Gürtel
    ("haut", (0.78, 0.62, 0.50), 0.7, 0.0),  # 2 Augenpartie
    ("binde", (0.22, 0.20, 0.17), 0.9, 0.0),  # 3 Bandagen
    ("stahl", (0.62, 0.64, 0.68), 0.35, 0.8),  # 4 Schwert
    ("griff", (0.08, 0.06, 0.05), 0.8, 0.0),  # 5 Schwertgriff
    ("dunkel", (0.02, 0.02, 0.025), 0.8, 0.0),  # 6 Schuhe, Handschuhe, Scheide
]
STOFF, ROT, HAUT, BINDE, STAHL, GRIFF, DUNKEL = range(7)

# --- Skelett (Armature-Raum, x = rechts, y = vorn, z = oben) -------------------------------------
# name: (Elternknochen, Kopf, Ende)
BONES = {
    "root": (None, (0, 0, 0), (0, 0, 0.2)),
    "hips": ("root", (0, 0, 0.98), (0, 0, 1.08)),
    "spine": ("hips", (0, 0, 1.08), (0, 0, 1.27)),
    "chest": ("spine", (0, 0, 1.27), (0, 0, 1.50)),
    "neck": ("chest", (0, 0, 1.50), (0, 0, 1.60)),
    "head": ("neck", (0, 0, 1.60), (0, 0, 1.85)),
    "scarf_1": ("neck", (0, -0.09, 1.55), (0, -0.32, 1.50)),
    "scarf_2": ("scarf_1", (0, -0.32, 1.50), (0, -0.56, 1.42)),
    "scarf_3": ("scarf_2", (0, -0.56, 1.42), (0, -0.80, 1.33)),
}
SIDES = {"l": -1.0, "r": 1.0}  # anatomisch: links = -x bei Blick nach +y
for _n, _s in SIDES.items():
    BONES[f"upper_arm_{_n}"] = ("chest", (_s * 0.265, 0, 1.44), (_s * 0.265, 0, 1.14))
    BONES[f"forearm_{_n}"] = (f"upper_arm_{_n}", (_s * 0.265, 0, 1.14), (_s * 0.265, 0, 0.90))
    BONES[f"hand_{_n}"] = (f"forearm_{_n}", (_s * 0.265, 0, 0.90), (_s * 0.265, 0, 0.80))
    BONES[f"thigh_{_n}"] = ("hips", (_s * 0.10, 0, 0.98), (_s * 0.10, 0, 0.54))
    BONES[f"shin_{_n}"] = (f"thigh_{_n}", (_s * 0.10, 0, 0.54), (_s * 0.10, 0, 0.10))
    BONES[f"foot_{_n}"] = (f"shin_{_n}", (_s * 0.10, 0, 0.10), (_s * 0.10, 0.16, 0.04))

THIGH_LEN = 0.44
SHIN_LEN = 0.44


# --- Geometrie ---------------------------------------------------------------------------------
class MeshBuilder:
    """Sammelt alle Körperteile in einem Mesh; jedes Teil gehört voll zu einem Knochen."""

    def __init__(self):
        self.bm = bmesh.new()
        self.deform = self.bm.verts.layers.deform.verify()
        self.groups = list(BONES.keys())

    def _finish(self, verts, bone, material, smooth):
        index = self.groups.index(bone)
        faces = {f for v in verts for f in v.link_faces}
        for f in faces:
            f.material_index = material
            f.smooth = smooth
        for v in verts:
            v[self.deform][index] = 1.0

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
                ring.append(self.bm.verts.new((rx * math.sin(ang), ry * math.cos(ang), z)))
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

    # Rumpf: ein glatter Verlauf von der Hüfte bis zu den Schultern
    torso = [
        (0.93, 0.17, 0.12),
        (1.00, 0.195, 0.135),
        (1.08, 0.175, 0.125),
        (1.16, 0.155, 0.112),
        (1.26, 0.18, 0.12),
        (1.36, 0.215, 0.135),
        (1.46, 0.215, 0.13),
        (1.52, 0.14, 0.10),
    ]
    m.loft(torso, [("hips", 1.03), ("spine", 1.18), ("chest", 1.40)], STOFF)
    m.ellipsoid("hips", (0, 0, 1.075), (0.19, 0.14, 0.035), ROT)  # Gürtel
    m.box("hips", (0, -0.14, 1.075), (0.09, 0.05, 0.08), ROT)  # Gürtelknoten

    # Kopf mit Kapuze, Augenpartie und Haarknoten
    m.cylinder("neck", (0, 0, 1.56), 0.058, 0.14, STOFF)
    m.ellipsoid("head", (0, 0, 1.72), (0.125, 0.14, 0.14), STOFF)
    m.box("head", (0, 0.122, 1.725), (0.15, 0.045, 0.05), HAUT)
    for side in (-1, 1):
        m.box("head", (side * 0.04, 0.147, 1.727), (0.035, 0.012, 0.014), DUNKEL)  # Augen
    m.box("head", (0, 0.127, 1.762), (0.17, 0.04, 0.012), DUNKEL)  # Stirnband
    m.ellipsoid("head", (0, -0.11, 1.81), (0.045, 0.055, 0.055), STOFF)  # Haarknoten
    m.ellipsoid("neck", (0, 0, 1.55), (0.118, 0.118, 0.045), ROT)  # Schal um den Hals

    # Schalenden
    points = [(0, -0.09, 1.55), (0, -0.32, 1.50), (0, -0.56, 1.42), (0, -0.80, 1.33)]
    widths = [0.13, 0.12, 0.10]
    for i, bone in enumerate(["scarf_1", "scarf_2", "scarf_3"]):
        a, b = points[i], points[i + 1]
        mid = (Vector(a) + Vector(b)) / 2
        length = (Vector(b) - Vector(a)).length
        m.box(bone, mid, (widths[i], length, 0.014), ROT, matrix=aligned(a, b))
        # zweiter, senkrechter Streifen: von der Seite und von hinten sichtbar
        m.box(bone, mid, (0.014, length, widths[i] * 0.75), ROT, matrix=aligned(a, b))

    # Arme und Beine
    for n, side in SIDES.items():
        x = side * 0.265
        m.capsule(f"upper_arm_{n}", (x, 0, 1.43), (x, 0, 1.15), 0.068, 0.056, STOFF)
        m.capsule(f"forearm_{n}", (x, 0, 1.15), (x, 0, 0.92), 0.056, 0.046, BINDE)
        m.ellipsoid(f"hand_{n}", (x, 0.005, 0.86), (0.045, 0.04, 0.06), DUNKEL)
        x = side * 0.10
        m.capsule(f"thigh_{n}", (x, 0, 0.97), (x, 0, 0.55), 0.108, 0.078, STOFF)
        m.capsule(f"shin_{n}", (x, 0, 0.54), (x, 0, 0.14), 0.074, 0.052, BINDE)
        m.ellipsoid(f"foot_{n}", (x, 0.055, 0.052), (0.068, 0.13, 0.052), DUNKEL)

    # Schwert auf dem Rücken: Griff über der rechten Schulter, Scheide nach links unten
    top = Vector((0.13, -0.17, 1.80))
    guard = Vector((0.095, -0.17, 1.70))
    tip = Vector((-0.18, -0.17, 0.96))
    m.cylinder("chest", (top + guard) / 2, 0.016, (top - guard).length, GRIFF, matrix=z_aligned(guard, top))
    m.cylinder("chest", guard, 0.048, 0.012, STAHL, matrix=z_aligned(guard, top))  # Stichblatt
    m.box("chest", (guard + tip) / 2, (0.05, (tip - guard).length, 0.036), DUNKEL, matrix=aligned(guard, tip))

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


def legs(thigh_l, knee_l, thigh_r, knee_r, stand=0.88):
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
    return {
        "scarf_1": (a1, 0, sway),
        "scarf_2": (a2, 0, sway * 1.3),
        "scarf_3": (a3, 0, sway * 1.6),
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


def run_pose(t):
    p = 2 * math.pi * t
    pose = {}
    thighs, knees = {}, {}
    for n, off in (("l", 0.0), ("r", math.pi)):
        th = p + off
        thighs[n] = 46 * math.sin(th) + 6
        knees[n] = 14 + 78 * max(0.0, math.cos(th - 0.35)) ** 1.4
    legs_pose, dz = legs(thighs["l"], knees["l"], thighs["r"], knees["r"])
    pose.update(legs_pose)
    pose.update(hips_pose(dz, pitch=-6, yaw=7 * math.sin(p), roll=3 * math.sin(p)))
    pose["spine"] = (-7, 0, -6 * math.sin(p))
    pose["chest"] = (-7, 0, -6 * math.sin(p))
    pose["head"] = (10, 0, 2 * math.sin(p))
    for n, off in (("l", math.pi), ("r", 0.0)):  # Arm gegenläufig zum gleichseitigen Bein
        th = p + off
        pose[f"upper_arm_{n}"] = (-44 * math.sin(th) + 6, 0, -8 if n == "l" else 8)
        pose[f"forearm_{n}"] = (72 + 20 * math.cos(th), 0, 0)
        pose[f"hand_{n}"] = (6, 0, 0)
    pose.update(scarf(-22 + 8 * math.sin(2 * p + 0.5), -12 + 10 * math.sin(2 * p - 0.3), -4 + 12 * math.sin(2 * p - 1.0), 7 * math.sin(p)))
    return pose


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
    ("run-loop", 18, run_pose, True),
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
    cam_data.ortho_scale = 2.4
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
    "seite": ((5.0, 0.0, 0.95), (90, 0, 90)),
    "vorn": ((0.0, 5.0, 0.95), (90, 0, 180)),
    "hinten": ((0.0, -5.0, 0.95), (90, 0, 0)),
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
        ("run-loop", 5, "seite"),
        ("run-loop", 9, "seite"),
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

    if preview:
        make_previews(rig, actions, preview)
    export_glb(out)
    tris = sum(len(p.vertices) - 2 for p in mesh_obj.data.polygons)
    print(f"Fertig: {out} – {len(mesh_obj.data.vertices)} Punkte, {tris} Dreiecke (Umriss-Mesh zusätzlich), {len(actions)} Animationen")


main()
