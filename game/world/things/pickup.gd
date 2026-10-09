class_name Pickup
extends Area3D
## Something the hero collects by touching it: a coin, a silver coin (the
## timed challenges), a hidden gem, a heart or a star. Stars and gems found
## on an earlier visit show as see-through and can be collected again for
## nothing new.

signal collected

const SPIN := 2.4
const MODELS := {
	"coin": ["coin-gold", 1.3],
	"silver": ["coin-silver", 1.6],
	"gem": ["jewel", 1.7],
	"heart": ["heart", 1.4],
	"star": ["star", 2.6],
}

var level: Level
var kind := "coin"
var id := ""
## Already found before (stars and gems).
var found := false

var _model: Node3D
var _t := 0.0
var _taken := false


static func make(p_kind: String, p_id := "", p_found := false) -> Pickup:
	var p := Pickup.new()
	p.kind = p_kind
	p.id = p_id
	p.found = p_found
	return p


func _init() -> void:
	collision_layer = 0
	collision_mask = Kit.LAYER_HERO
	# Set before entering the tree: things appear from inside physics signals.
	monitorable = false


func _ready() -> void:
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.6 if kind == "star" else 0.42
	shape.shape = sphere
	shape.position.y = 0.35
	add_child(shape)
	var m: Array = MODELS.get(kind, MODELS.coin)
	_model = Kit.model(m[0], m[1])
	add_child(_model)
	_t = fmod(position.x * 0.7 + position.z * 0.3, TAU)
	if found:
		_ghost_look(_model)
	if kind == "star":
		var light := OmniLight3D.new()
		light.light_color = Color("ffe58a") if not found else Color("9ad0ff")
		light.light_energy = 1.2
		light.omni_range = 3.0
		light.position.y = 0.5
		add_child(light)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_t += delta
	if _model:
		_model.rotation.y = _t * (SPIN * 0.6 if kind == "star" else SPIN)
		_model.position.y = sin(_t * 2.0) * (0.12 if kind in ["star", "gem"] else 0.05)


func _on_body_entered(body: Node3D) -> void:
	if _taken or body != level.hero:
		return
	_taken = true
	match kind:
		"coin":
			level.collect_coins(1)
			LGAudio.play_sfx("res://assets/kenney/audio/sfx/sfx_coin.ogg", -8.0, 0.08)
		"silver":
			LGAudio.play_sfx("res://assets/kenney/audio/sfx/sfx_gem.ogg", -4.0, 0.03)
		"gem":
			level.collect_gem(id)
			LGAudio.play_sfx("res://assets/kenney/audio/sfx/sfx_magic.ogg", -2.0)
		"heart":
			level.collect_heart()
			LGAudio.play_sfx("res://assets/kenney/audio/sfx/sfx_select.ogg", -4.0)
		"star":
			level.collect_star(id)
	collected.emit()
	_pop()


func _pop() -> void:
	set_deferred("monitoring", false)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3.ONE * 1.4, 0.08)
	tw.tween_property(self, "scale", Vector3.ONE * 0.01, 0.14)
	tw.tween_callback(queue_free)


## See-through and blue, for things found on an earlier visit.
static func _ghost_look(n: Node) -> void:
	if n is MeshInstance3D:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.55, 0.78, 1.0, 0.5)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.emission_enabled = true
		mat.emission = Color(0.25, 0.45, 0.8)
		(n as MeshInstance3D).material_override = mat
	for c in n.get_children():
		_ghost_look(c)
