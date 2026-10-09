class_name SkywayBridge
extends Node3D
## A stretch of the Skyway: a rainbow bridge that fades back in once enough
## stars are found.

var level: Level
var to := Vector3(10, 0, 0)
var width := 2.4
var shown := false

var _mesh: MeshInstance3D
var _shape: CollisionShape3D
var _body: StaticBody3D

const BANDS := [Color("ff5a5f"), Color("ffa94d"), Color("ffe066"), Color("69db7c"), Color("4dabf7"), Color("9775fa")]


func _ready() -> void:
	_body = StaticBody3D.new()
	_body.collision_layer = 0
	_body.collision_mask = 0
	add_child(_body)
	_shape = CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(width, 0.3, to.length())
	_shape.shape = box
	_shape.position = to / 2.0 + Vector3.DOWN * 0.15
	_shape.basis = Basis.looking_at(to.normalized(), Vector3.UP)
	_body.add_child(_shape)
	_mesh = MeshInstance3D.new()
	_mesh.mesh = _ribbon()
	# Built along +z, so growing its z scale draws it out across the gap.
	_mesh.basis = Basis.looking_at(-to.normalized(), Vector3.UP)
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 0.35
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mesh.material_override = mat
	add_child(_mesh)
	_mesh.visible = false


## The rainbow: one strip per colour band.
func _ribbon() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var along := Vector3(0, 0, to.length())
	var side := Vector3.RIGHT
	var steps := 24
	for b in BANDS.size():
		var w0 := -width / 2.0 + width * b / BANDS.size()
		var w1 := -width / 2.0 + width * (b + 1) / BANDS.size()
		var c: Color = BANDS[b]
		for i in steps:
			var t0 := float(i) / steps
			var t1 := float(i + 1) / steps
			var p0 := along * t0 + Vector3.UP * 0.02
			var p1 := along * t1 + Vector3.UP * 0.02
			var quad := [p0 + side * w0, p0 + side * w1, p1 + side * w1, p1 + side * w0]
			for idx in [0, 1, 2, 0, 2, 3]:
				st.set_color(c)
				st.set_normal(Vector3.UP)
				st.add_vertex(quad[idx])
	return st.commit()


func show_bridge(animate := true) -> void:
	if shown:
		return
	shown = true
	_body.collision_layer = Kit.LAYER_WORLD
	_mesh.visible = true
	if animate:
		_mesh.scale = Vector3(1, 1, 0.01)
		var tw := create_tween()
		tw.tween_property(_mesh, "scale", Vector3.ONE, 1.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
