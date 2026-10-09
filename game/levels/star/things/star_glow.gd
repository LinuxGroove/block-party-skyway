class_name StarGlow
extends Node3D
## A big star that glows and turns slowly: the Star Road's scenery (no
## collision, nothing to collect).

var size := 2.0
var color := Color("ffd84a")
## Adds a little light around it (keep these few).
var light := false
var spin := 0.6
var bob := 0.15

var _model: Node3D
var _t := 0.0


static func make(p_size := 2.0, p_color := Color("ffd84a"), p_light := false) -> StarGlow:
	var g := StarGlow.new()
	g.size = p_size
	g.color = p_color
	g.light = p_light
	return g


func _ready() -> void:
	_model = Kit.model("star", size)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.1
	mat.roughness = 0.4
	for m in _model.find_children("*", "MeshInstance3D", true, false):
		(m as MeshInstance3D).material_override = mat
		(m as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_model)
	_t = fmod(absf(position.x * 0.37 + position.z * 0.21), TAU)
	if light:
		var l := OmniLight3D.new()
		l.light_color = color
		l.light_energy = 1.4
		l.omni_range = size * 2.5
		l.position.y = size * 0.2
		add_child(l)


func _process(delta: float) -> void:
	_t += delta
	_model.rotation.y = _t * spin
	_model.position.y = sin(_t * 1.4) * bob
