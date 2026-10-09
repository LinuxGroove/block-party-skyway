class_name StationRunaway
extends Area3D
## Comet, a space bunny who has hopped out of the garden: she runs from the
## hero when they come near, keeping inside her patch, and stops once
## touched. A walker can't catch her; a runner can, best in a corner.

signal caught

var level: Level
## Where she keeps to (only x and z count).
var bounds := AABB(Vector3(-5, 0, -5), Vector3(10, 1, 10))
var speed := 5.2
var flee_range := 6.0
var is_caught := false

var _rig: RigCharacter
var _hop := 0.0
var _home := Vector3.ZERO


func _init() -> void:
	collision_layer = 0
	collision_mask = Kit.LAYER_HERO
	monitorable = false


func _ready() -> void:
	_home = position
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.8, 0.8, 0.8)
	shape.shape = box
	shape.position.y = 0.4
	add_child(shape)
	_rig = RigCharacter.create(Kit.scene("animal-bunny"), 0.34)
	add_child(_rig)
	_rig.play("idle")
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if is_caught or level == null or level.hero == null:
		return
	var h := level.hero
	var away := global_position - h.global_position
	away.y = 0.0
	var move := Vector3.ZERO
	if away.length() < flee_range:
		move = away.normalized() if away.length() > 0.01 else Vector3.RIGHT
		# At an edge of her patch she runs along it instead.
		var next := position + move * 0.6
		if next.x < bounds.position.x or next.x > bounds.end.x:
			move.x = 0.0
		if next.z < bounds.position.z or next.z > bounds.end.z:
			move.z = 0.0
		move = move.normalized() if move.length() > 0.2 else Vector3.ZERO
	if move != Vector3.ZERO:
		position += move * speed * delta
		position.x = clampf(position.x, bounds.position.x, bounds.end.x)
		position.z = clampf(position.z, bounds.position.z, bounds.end.z)
		_rig.rotation.y = lerp_angle(_rig.rotation.y, atan2(move.x, move.z), 1.0 - exp(-12.0 * delta))
		_hop += delta * 9.0
		_rig.position.y = absf(sin(_hop)) * 0.3
		_rig.play("run")
	else:
		_rig.position.y = move_toward(_rig.position.y, 0.0, delta * 2.0)
		_rig.play("idle")
	if overlaps_body(h):
		catch()


func _on_body_entered(body: Node3D) -> void:
	if level and body == level.hero:
		catch()


func catch() -> void:
	if is_caught:
		return
	is_caught = true
	set_deferred("monitoring", false)
	_rig.position.y = 0.0
	_rig.play("dance")
	LGAudio.play_sfx("res://assets/kenney/audio/sfx/sfx_select.ogg", 0.0)
	caught.emit()
