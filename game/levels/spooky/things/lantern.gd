class_name SpookyLantern
extends Area3D
## A big pumpkin lantern that has gone out. Touch it and it lights up and
## glows for good, for Hazel's request on Spooky Hollow.

signal lit(lantern: SpookyLantern)

const COLOR := Color("ff9d3a")

var level: Level
var is_lit := false

var _model: Node3D
var _light: OmniLight3D
var _flame: MeshInstance3D


func _init() -> void:
	collision_layer = 0
	collision_mask = Kit.LAYER_HERO
	# Set before entering the tree: things appear from inside physics signals.
	monitorable = false


func _ready() -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.3, 1.4, 1.3)
	shape.shape = box
	shape.position.y = 0.7
	add_child(shape)
	_model = Kit.model("grave:pumpkin-carved", 2.8)
	add_child(_model)
	_flame = MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = 0.16
	ball.height = 0.32
	_flame.mesh = ball
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color("ffe08a")
	_flame.material_override = mat
	_flame.position.y = 0.45
	add_child(_flame)
	_light = OmniLight3D.new()
	_light.light_color = COLOR
	_light.omni_range = 6.0
	_light.position.y = 0.9
	add_child(_light)
	_show(is_lit)
	body_entered.connect(_on_body_entered)


func _process(_delta: float) -> void:
	if is_lit:
		# A flicker.
		var t := Time.get_ticks_msec()
		_light.light_energy = 2.0 + sin(t * 0.011) * 0.15
		_flame.scale = Vector3.ONE * (1.0 + sin(t * 0.017) * 0.12)


func _on_body_entered(body: Node3D) -> void:
	if level and body == level.hero and not is_lit:
		light_up()


func light_up() -> void:
	if is_lit:
		return
	is_lit = true
	_show(true)
	LGAudio.play_sfx("res://assets/kenney/audio/sfx/sfx_magic.ogg", -4.0, 0.05)
	var tw := create_tween()
	tw.tween_property(_model, "scale", Vector3.ONE * 3.3, 0.12)
	tw.tween_property(_model, "scale", Vector3.ONE * 2.8, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	lit.emit(self)


func _show(on: bool) -> void:
	_flame.visible = on
	_light.visible = on
	_light.light_energy = 2.0
