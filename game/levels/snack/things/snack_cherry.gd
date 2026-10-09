class_name SnackCherry
extends Area3D
## A runaway cherry, bigger than the hero. Touch it and it hops home to
## the top of a sundae.

signal found(cherry: SnackCherry)

var level: Level
var home := Vector3.ZERO
var is_home := false
var model_scale := 5.0

var _model: Node3D
var _t := 0.0


func _init() -> void:
	collision_layer = 0
	collision_mask = Kit.LAYER_HERO
	monitorable = false


func _ready() -> void:
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.55
	shape.shape = sphere
	shape.position.y = 0.4
	add_child(shape)
	_model = Kit.model("food:cherries", model_scale)
	add_child(_model)
	_t = position.x
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_t += delta
	if not is_home:
		_model.rotation.y = sin(_t * 1.1) * 0.8
		_model.position.y = absf(sin(_t * 2.4)) * 0.15


func _on_body_entered(body: Node3D) -> void:
	if level == null or body != level.hero or is_home:
		return
	go_home()


func go_home() -> void:
	if is_home:
		return
	is_home = true
	set_deferred("monitoring", false)
	LGAudio.play_sfx("res://assets/kenney/audio/sfx/sfx_select.ogg", 0.0)
	_model.position.y = 0.0
	var tw := create_tween()
	var mid := (position + home) / 2.0 + Vector3.UP * 5.0
	tw.tween_property(self, "position", mid, 0.6).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position", home, 0.6).set_ease(Tween.EASE_IN)
	tw.tween_callback(_arrived)


func _arrived() -> void:
	found.emit(self)
