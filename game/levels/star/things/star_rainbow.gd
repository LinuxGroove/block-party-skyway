class_name StarRainbow
extends Node3D
## A rainbow arching over the Star Road: half a ring of the Skyway's six
## colours, standing on two feet `radius` apart from its middle. Scenery.

var radius := 8.0
var band := 0.35
## Turned this many degrees about y (0 spans east to west, facing south).
var turn := 0.0


static func make(p_radius := 8.0, p_turn := 0.0, p_band := 0.35) -> StarRainbow:
	var r := StarRainbow.new()
	r.radius = p_radius
	r.turn = p_turn
	r.band = p_band
	return r


func _ready() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps := 48
	var bands: Array = SkywayBridge.BANDS
	for b in bands.size():
		var r0 := radius - band * (bands.size() - b)
		var r1 := r0 + band
		# Red on the outside, like a real one.
		var c: Color = bands[bands.size() - 1 - b]
		for i in steps:
			var a0 := PI * i / steps
			var a1 := PI * (i + 1) / steps
			var p := [Vector3(cos(a0) * r0, sin(a0) * r0, 0), Vector3(cos(a0) * r1, sin(a0) * r1, 0),
				Vector3(cos(a1) * r1, sin(a1) * r1, 0), Vector3(cos(a1) * r0, sin(a1) * r0, 0)]
			for idx in [0, 1, 2, 0, 2, 3]:
				st.set_color(c)
				st.set_normal(Vector3.BACK)
				st.add_vertex(p[idx])
	var mesh := MeshInstance3D.new()
	mesh.mesh = st.commit()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 0.5
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material_override = mat
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh.rotation_degrees.y = turn
	add_child(mesh)
