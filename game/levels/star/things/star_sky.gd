class_name StarSky
extends Node3D
## The Star Road's night: a field of stars and a big moon that stay far off
## (they follow the camera, like the sky), and a sea of clouds far below the
## islands. Scenery only; the Star Road's levels add one with their sky.

const SEED := 1977
const STARS := 520
const STAR_COLORS := [Color("ffffff"), Color("fff3c4"), Color("cfe0ff"), Color("ffd6f5")]

## The middle of the cloud sea and how far it spreads.
var center := Vector3.ZERO
var spread := 90.0
## How far below the level's floor the clouds float.
var depth := -24.0

var _field: Node3D


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	_field = Node3D.new()
	_field.top_level = true
	add_child(_field)
	_stars(rng)
	_moon()
	_clouds(rng)


func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam:
		_field.global_position = cam.global_position


func _unshaded(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.disable_fog = true
	return mat


## Small dots all round, thinning out low down where the clouds are.
func _stars(rng: RandomNumberGenerator) -> void:
	var dot := SphereMesh.new()
	dot.radius = 0.5
	dot.height = 1.0
	dot.radial_segments = 6
	dot.rings = 3
	var mat := _unshaded(Color.WHITE)
	mat.vertex_color_use_as_albedo = true
	dot.material = mat
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = dot
	mm.instance_count = STARS
	for i in STARS:
		var dir := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.25, 1.0), rng.randf_range(-1, 1)).normalized()
		var size := rng.randf_range(0.7, 1.6) if rng.randf() < 0.85 else rng.randf_range(1.8, 2.6)
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * size), dir * rng.randf_range(300.0, 360.0)))
		var c: Color = STAR_COLORS[rng.randi() % STAR_COLORS.size()]
		mm.set_instance_color(i, c * rng.randf_range(0.7, 1.0))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_field.add_child(mmi)


func _moon() -> void:
	var moon := MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = 16.0
	ball.height = 32.0
	moon.mesh = ball
	moon.material_override = _unshaded(Color("fff0c2"))
	moon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	moon.position = Vector3(-170, 150, -230)
	_field.add_child(moon)
	# A soft halo behind it.
	var halo := MeshInstance3D.new()
	var disc := SphereMesh.new()
	disc.radius = 26.0
	disc.height = 52.0
	halo.mesh = disc
	var hm := _unshaded(Color(1.0, 0.92, 0.7, 0.18))
	hm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	halo.material_override = hm
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	halo.position = moon.position * 1.04
	_field.add_child(halo)


## Flat puffs far below, lit by the moon.
func _clouds(rng: RandomNumberGenerator) -> void:
	var puff := SphereMesh.new()
	puff.radial_segments = 16
	puff.rings = 8
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("7a6bc4")
	mat.emission_enabled = true
	mat.emission = Color("2b2160")
	mat.roughness = 1.0
	puff.material = mat
	var n := int(clampf(spread * spread / 160.0, 24.0, 90.0))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = puff
	mm.instance_count = n
	for i in n:
		var a := rng.randf() * TAU
		var r := sqrt(rng.randf()) * spread
		var at := center + Vector3(cos(a) * r, depth + rng.randf_range(-3.0, 2.0), sin(a) * r)
		var s := Vector3(rng.randf_range(9.0, 18.0), rng.randf_range(2.0, 3.5), rng.randf_range(7.0, 14.0))
		mm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(s), at))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)
