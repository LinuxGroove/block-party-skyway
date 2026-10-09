class_name SpookyGhost
extends Critter
## A ghost on its rounds: it floats up and down with a pale glow, and it's
## too spiky to jump on. Only a ground pound beats it.
##
##   add(SpookyGhost.drift(Vector3(4, 0, 0)), at)   # at is where it floats from


static func drift(p_travel: Vector3, p_period := 4.0, p_phase := 0.0) -> SpookyGhost:
	var g := SpookyGhost.new()
	g.model_name = "grave:character-ghost"
	g.travel = p_travel
	g.period = p_period
	g.phase = p_phase
	g.model_scale = 1.15
	g.spiky = true
	g.bob = 0.22
	g.size = Vector3(0.8, 0.85, 0.6)
	g.coins = 3
	return g


func _ready() -> void:
	super()
	_rig.play("idle")
	_see_through(_rig)
	var light := OmniLight3D.new()
	light.light_color = Color("bfd4ff")
	light.light_energy = 0.7
	light.omni_range = 2.6
	light.position.y = 0.6
	add_child(light)


## A little see-through, and glowing faintly.
func _see_through(n: Node) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		for i in mi.mesh.get_surface_count():
			var base := mi.mesh.surface_get_material(i)
			var mat: StandardMaterial3D = base.duplicate() if base is StandardMaterial3D else StandardMaterial3D.new()
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.albedo_color.a = 0.82
			mat.emission_enabled = true
			mat.emission = Color("8fa8e0")
			mat.emission_energy_multiplier = 0.35
			mi.set_surface_override_material(i, mat)
	for c in n.get_children():
		_see_through(c)
