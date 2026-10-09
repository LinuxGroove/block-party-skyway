class_name BlobShadow
extends MeshInstance3D
## A soft dark disc on the ground straight under the hero, on top of the real
## shadow, so it's easy to see where a jump will land.

const SIZE := 0.75
const REACH := 40.0

var hero: Node3D


func _ready() -> void:
	top_level = true
	# Placed every tick from a ray, so smoothing it would only add lag.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var quad := QuadMesh.new()
	quad.size = Vector2(SIZE, SIZE)
	quad.orientation = PlaneMesh.FACE_Y
	mesh = quad
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_texture = disc_texture()
	mat.albedo_color = Color(0.05, 0.08, 0.15, 0.55)
	mat.render_priority = 1
	mat.no_depth_test = false
	material_override = mat


func _process(_delta: float) -> void:
	if hero == null or not is_instance_valid(hero):
		return
	var from: Vector3 = hero.get_global_transform_interpolated().origin + Vector3.UP * 0.3
	var space := hero.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * REACH, 1)
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		visible = false
		return
	visible = true
	var n: Vector3 = hit.normal
	var at: Vector3 = hit.position
	var height := from.y - at.y
	var s := clampf(1.0 - height / 30.0, 0.55, 1.0)
	var b := Basis.looking_at(n.cross(Vector3.RIGHT) if absf(n.x) < 0.9 else n.cross(Vector3.FORWARD), n) if n.y < 0.999 else Basis.IDENTITY
	global_transform = Transform3D(b.scaled(Vector3(s, 1.0, s)), at + n * 0.03)


static func disc_texture() -> Texture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.6, Color(1, 1, 1, 0.9))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 64
	tex.height = 64
	return tex
