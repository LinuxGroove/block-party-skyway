class_name PadButton
extends Area3D
## A big round button on the ground. Step on it to start something.

signal pressed

var level: Level
var down := false

var _model: Node3D


func _init() -> void:
	collision_layer = 0
	collision_mask = Kit.LAYER_HERO
	# Set before entering the tree: things appear from inside physics signals.
	monitorable = false


func _ready() -> void:
	add_to_group("poundable")
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.9, 0.4, 0.9)
	shape.shape = box
	shape.position.y = 0.2
	add_child(shape)
	_model = Kit.model("button-round", 1.8)
	add_child(_model)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if body == level.hero:
		pound()


func pound() -> void:
	if down:
		return
	down = true
	LGAudio.play_sfx("res://assets/kenney/audio/sfx/sfx_select.ogg", -2.0)
	var anim := _model.find_children("*", "AnimationPlayer", true, false)
	if not anim.is_empty():
		anim[0].play("toggle-on")
	pressed.emit()


func release() -> void:
	down = false
	var anim := _model.find_children("*", "AnimationPlayer", true, false)
	if not anim.is_empty():
		anim[0].play("toggle-off")
