class_name Checkpoint
extends Area3D
## A flag. Touch it and it's where the hero comes back after a fall.

var level: Level
var facing := Vector3.FORWARD
var reached := false

var _flag: Node3D


func _init() -> void:
	collision_layer = 0
	collision_mask = Kit.LAYER_HERO
	# Set before entering the tree: things appear from inside physics signals.
	monitorable = false


func _ready() -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.6, 2.0, 1.6)
	shape.shape = box
	shape.position.y = 1.0
	add_child(shape)
	_flag = Kit.model("flag", 1.6)
	_flag.rotation.y = atan2(facing.x, facing.z) + PI / 2.0
	add_child(_flag)
	_flag.scale.y = 0.6
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if body != level.hero or reached:
		return
	reached = true
	level.reach_checkpoint(global_position + Vector3.UP * 0.1, facing)
	LGAudio.play_sfx("res://assets/kenney/audio/sfx/confirmation_001.ogg", -4.0)
	var tw := create_tween()
	tw.tween_property(_flag, "scale", Vector3(1.6, 1.8, 1.6), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
