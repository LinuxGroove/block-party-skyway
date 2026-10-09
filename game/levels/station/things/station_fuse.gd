class_name StationFuse
extends Area3D
## One of the station's lost fuses: a glowing canister. Touch it and it
## zips back to Sprocket's console.

signal found(fuse: StationFuse)

var level: Level
var home := Vector3.ZERO
var is_home := false

var _model: Node3D
var _t := 0.0


func _init() -> void:
	collision_layer = 0
	collision_mask = Kit.LAYER_HERO
	monitorable = false


func _ready() -> void:
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.5
	shape.shape = sphere
	shape.position.y = 0.4
	add_child(shape)
	_model = Kit.model("station:container", 1.1)
	_model.position.y = 0.1
	add_child(_model)
	var light := OmniLight3D.new()
	light.light_color = Color("9fe3f0")
	light.light_energy = 1.0
	light.omni_range = 2.2
	light.position.y = 0.5
	add_child(light)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_t += delta
	if not is_home:
		_model.rotation.y = _t * 1.5
		_model.position.y = 0.1 + sin(_t * 2.0) * 0.08


func _on_body_entered(body: Node3D) -> void:
	if level == null or body != level.hero or is_home:
		return
	go_home()


func go_home() -> void:
	if is_home:
		return
	is_home = true
	set_deferred("monitoring", false)
	LGAudio.play_sfx("res://assets/kenney/audio/sfx/sfx_magic.ogg", -4.0)
	var tw := create_tween()
	var mid := (position + home) / 2.0 + Vector3.UP * 4.0
	tw.tween_property(self, "position", mid, 0.6).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position", home, 0.6).set_ease(Tween.EASE_IN)
	tw.tween_callback(_arrived)


func _arrived() -> void:
	_model.rotation.y = 0.0
	found.emit(self)
