class_name PirateThief
extends Area3D
## A cheeky islander who has pinched something and won't give it back: he
## runs off when the hero comes near, staying inside his patch of beach, and
## only gives up when caught (touched, jumped on or dived into). Being
## faster, the hero can corner him.

signal caught

var level: Level
var model_name := "animal-fox"
var model_scale := 0.4
## He runs within this box (x and z, at his own height).
var bounds := Rect2(-6, -6, 12, 12)
var speed := 5.4
## He notices the hero this close.
var wary := 7.0
var is_caught := false

var _rig: RigCharacter
var _dodge := 0.0
var _side := 1.0


func _init() -> void:
	collision_layer = 0
	collision_mask = Kit.LAYER_HERO
	# Set before entering the tree: things appear from inside physics signals.
	monitorable = false


func _ready() -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.9, 0.9, 0.9)
	shape.shape = box
	shape.position.y = 0.45
	add_child(shape)
	_rig = RigCharacter.create(Kit.scene(model_name), model_scale)
	add_child(_rig)
	_rig.play("idle")
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if is_caught or level == null or level.hero == null:
		return
	var h := level.hero
	var away := global_position - h.global_position
	away.y = 0.0
	var dist := away.length()
	if dist > wary:
		_rig.play("idle")
		_face(-away)
		return
	var dir := away.normalized() if dist > 0.01 else Vector3.RIGHT
	_dodge = maxf(_dodge - delta, 0.0)
	# Near an edge, run along it instead; boxed into a corner, dodge past.
	var p := Vector2(position.x, position.z)
	var margin := 1.2
	var blocked_x := (dir.x < 0.0 and p.x < bounds.position.x + margin) or (dir.x > 0.0 and p.x > bounds.end.x - margin)
	var blocked_z := (dir.z < 0.0 and p.y < bounds.position.y + margin) or (dir.z > 0.0 and p.y > bounds.end.y - margin)
	if blocked_x:
		dir.x = 0.0
	if blocked_z:
		dir.z = 0.0
	if dir.length() < 0.3 or _dodge > 0.0:
		if _dodge <= 0.0:
			_dodge = 0.6
			# Dodge along the edge he's on, towards the roomier side.
			var centre := bounds.get_center()
			_side = 1.0 if (p.x < centre.x) != (p.y < centre.y) else -1.0
		dir = Vector3(-away.z, 0, away.x).normalized() * _side
	dir = dir.normalized()
	position += dir * speed * delta
	position.x = clampf(position.x, bounds.position.x, bounds.end.x)
	position.z = clampf(position.z, bounds.position.y, bounds.end.y)
	_face(dir)
	_rig.play("run")
	if overlaps_body(h):
		_catch()


func _face(dir: Vector3) -> void:
	if dir.length() > 0.01:
		_rig.rotation.y = atan2(dir.x, dir.z)


func _on_body_entered(body: Node3D) -> void:
	if level and body == level.hero:
		_catch()


func _catch() -> void:
	if is_caught:
		return
	is_caught = true
	set_deferred("monitoring", false)
	_rig.play_once("gesture-negative")
	LGAudio.play_sfx("res://assets/kenney/audio/sfx/sfx_bump.ogg", -2.0, 0.1)
	caught.emit()
